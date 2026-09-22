package heimdall

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"

Console_Command_Run :: proc(args: []string)

Console_Command :: struct {
	name: string,
	run: Console_Command_Run,
}

console: bool

console_line: strings.Builder

console_registered_commands: map[string]Console_Command

// Lines are cloned, the caller keeps ownership of text
console_scrollback: [dynamic]string

console_register_command :: proc(cmd: Console_Command) {
	console_registered_commands[strings.clone(cmd.name)] = cmd
}

console_init :: proc() {
	console_line = strings.builder_make()
	input_set_raw_text_buffer(&console_line)
}

console_exit :: proc() {
	input_set_raw_text_buffer(nil)
	strings.builder_destroy(&console_line)
	for key in console_registered_commands {
		delete(key)
	}
	delete(console_registered_commands)
	console_registered_commands = {}
}

console_run_command :: proc(cmd_name: string, args: []string) -> bool {
	cmd, found := console_registered_commands[cmd_name]
	if !found {
		return false
	}
	cmd.run(args)
	return true
}

console_draw :: proc() {
	if console {
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
		rl.DrawText(strings.to_cstring(&console_line), prompt_width, input_line_y, font_size, rl.WHITE)

		// Newest scrollback line sits right above the input line, older ones climb the panel
		scrollback_line_x: i32 = 2
		scrollback_line_y := input_line_y - line_height
		#reverse for line in console_scrollback {
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

console_update :: proc() {
	if input.toggle_console {
		console = !console
	}

	if console && input.submit {
		line := strings.to_string(console_line)
		console_write_string(line)

		words := strings.fields(line, context.temp_allocator)
		if len(words) > 0 && !console_run_command(words[0], words[1:]) {
			warning("Unknown command '{}'", words[0])
		}

		strings.builder_reset(&console_line)
	}
}

console_write_string :: proc(text: string) {
	append(&console_scrollback, strings.clone(text))
}

console_printfln :: proc(format: string, args: ..any) {
	string_builder: strings.Builder
	fmt.sbprintf(&string_builder, format, ..args)
	console_write_string(strings.to_string(string_builder))
}
