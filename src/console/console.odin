package heimdall_console

import "../input"
import "../log"
import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Cmd_Run :: proc(args: []string)

Command :: struct {
	name:       string,
	short_help: string,
	help:       string,
	run:        Cmd_Run,
}

active: bool

buffer_line: strings.Builder

registered_commands: map[string]Command

// Lines are cloned, the caller keeps ownership of text
scrollback: [dynamic]string
history: [dynamic]string
history_index: int

register_command :: proc(cmd: Command) {
	registered_commands[strings.clone(cmd.name)] = cmd
}

init :: proc() {
	buffer_line = strings.builder_make()
	log.register_backend(write_string)
}

exit :: proc() {
	strings.builder_destroy(&buffer_line)
	for key in registered_commands {
		delete(key)
	}
	delete(registered_commands)
	registered_commands = {}
}

run_command :: proc(cmd_name: string, args: []string) -> bool {
	cmd, found := registered_commands[cmd_name]
	if !found {
		return false
	}
	cmd.run(args)
	return true
}

draw :: proc() {
	if active {
		// GetRender* report the render texture size while inside BeginTextureMode
		left_pad: i32 = 2
		font_size: i32 = 8
		line_height: i32 = font_size + 2
		panel_width := rl.GetRenderWidth()
		panel_height := rl.GetRenderHeight() / 2

		rl.DrawRectangle(0, 0, panel_width, panel_height, rl.Fade(rl.BLACK, 0.5))

		prompt: cstring : "> "
		prompt_width := rl.MeasureText(prompt, font_size) + 3

		// to_cstring terminates the builder in place, no allocation
		input_line_y := panel_height - line_height
		rl.DrawText(prompt, left_pad, input_line_y, font_size, rl.WHITE)
		rl.DrawText(strings.to_cstring(&buffer_line), prompt_width, input_line_y, font_size, rl.WHITE)

		// Newest scrollback line sits right above the input line, older ones climb the panel
		scrollback_line_x: i32 = left_pad
		scrollback_line_y := input_line_y - line_height
		#reverse for line in scrollback {
			if scrollback_line_y < 0 {
				break
			}
			rl.DrawText(
				strings.clone_to_cstring(line, context.temp_allocator),
				scrollback_line_x,
				scrollback_line_y,
				font_size,
				rl.WHITE,
			)
			scrollback_line_y -= line_height
		}
	}
}

update :: proc() {
	if input.state.toggle_console {
		active = !active
		if active {
			// occupy the raw input stream
			input.raw_text_buffer = &buffer_line
		} else {
			input.raw_text_buffer = nil
		}
	}

	if active && input.state.submit {
		line := strings.to_string(buffer_line)
		// Submitted input keeps the prompt in scrollback, the parsed text does not
		write_string(strings.concatenate({"> ", line}, context.temp_allocator))
		append(&history, line)
		history_index = 0

		words := strings.fields(line, context.temp_allocator)
		if len(words) > 0 && !run_command(words[0], words[1:]) {
			log.warning("Unknown command '{}'", words[0])
		}

		strings.builder_reset(&buffer_line)
	}

	if active && input.state.console_prev {
		strings.builder_reset(&buffer_line)
		history_index = min(history_index + 1, len(history))
		if clone_res, clone_err := strings.clone(history[len(history) - 1]); clone_err != nil {
			//
		}
	}
}

write_string :: proc(text: string) {
	remaining := text
	for line in strings.split_lines_iterator(&remaining) {
		append(&scrollback, strings.clone(line))
	}
}

printfln :: proc(format: string, args: ..any) {
	string_builder: strings.Builder
	fmt.sbprintf(&string_builder, format, ..args)
	write_string(strings.to_string(string_builder))
}
