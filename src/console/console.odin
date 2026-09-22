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

help_cmd := Command {
	name       = "help",
	short_help = "displays help messages about commands",
	run        = help_cmd_run,
}

register_command :: proc(cmd: Command) {
	registered_commands[strings.clone(cmd.name)] = cmd
}

init :: proc() {
	buffer_line = strings.builder_make()
	input.set_raw_text_buffer(&buffer_line)
	register_command(help_cmd)
	log.register_backend(write_string)
}

exit :: proc() {
	input.set_raw_text_buffer(nil)
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
		font_size: i32 = 8
		line_height: i32 = font_size + 2
		panel_width := rl.GetRenderWidth()
		panel_height := rl.GetRenderHeight() / 2

		rl.DrawRectangle(0, 0, panel_width, panel_height, rl.Fade(rl.BLACK, 0.5))

		prompt: cstring : "> "
		prompt_width := rl.MeasureText(prompt, font_size)

		// to_cstring terminates the builder in place, no allocation
		input_line_y := panel_height - line_height
		rl.DrawText(prompt, 0, input_line_y, font_size, rl.WHITE)
		rl.DrawText(strings.to_cstring(&buffer_line), prompt_width, input_line_y, font_size, rl.WHITE)

		// Newest scrollback line sits right above the input line, older ones climb the panel
		scrollback_line_x: i32 = 2
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
	}

	if active && input.state.submit {
		line := strings.to_string(buffer_line)
		write_string(line)

		words := strings.fields(line, context.temp_allocator)
		if len(words) > 0 && !run_command(words[0], words[1:]) {
			log.warning("Unknown command '{}'", words[0])
		}

		strings.builder_reset(&buffer_line)
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

help_cmd_run :: proc(args: []string) {
	if len(args) > 0 {
		cmd, found := registered_commands[args[0]]
		if !found {
			printfln("Unknown command '{}'", args[0])
			return
		}
		printfln("{} - {}", cmd.name, cmd.short_help)
		if cmd.help != "" {
			printfln("{}", cmd.help)
		}
		return
	}

	for name, cmd in registered_commands {
		printfln("{} - {}", name, cmd.short_help)
	}
}
