package heimdall

import "core:strings"
import rl "vendor:raylib"

// Allows for various ways to write the binds in the config
Keybind :: union {
	rl.KeyboardKey,
	[1]rl.KeyboardKey,
	[2]rl.KeyboardKey,
	[3]rl.KeyboardKey,
}

Keybindings :: struct {
	move_up:        Keybind,
	move_left:      Keybind,
	move_down:      Keybind,
	move_right:     Keybind,
	action:         Keybind,
	quit:           Keybind,
	toggle_console: Keybind,
}

Input_State :: struct {
	raw:            bool, // raw mode ie. console active
	move:           [2]f32, // -1..1 on each axis, [0] = horizontal, [1] = vertical
	action:         bool,
	action_held:    bool,
	quit:           bool,
	toggle_console: bool,
	submit:         bool, // raw mode only: enter was pressed this frame
}

keybindings := Keybindings {
	move_up        = ([2]rl.KeyboardKey){rl.KeyboardKey.W, rl.KeyboardKey.UP},
	move_left      = ([2]rl.KeyboardKey){rl.KeyboardKey.A, rl.KeyboardKey.LEFT},
	move_down      = ([2]rl.KeyboardKey){rl.KeyboardKey.S, rl.KeyboardKey.DOWN},
	move_right     = ([2]rl.KeyboardKey){rl.KeyboardKey.D, rl.KeyboardKey.RIGHT},
	action         = ([2]rl.KeyboardKey){rl.KeyboardKey.E, rl.KeyboardKey.SPACE},
	quit           = ([2]rl.KeyboardKey){rl.KeyboardKey.Q, rl.KeyboardKey.ESCAPE},
	toggle_console = rl.KeyboardKey.GRAVE,
}

input: Input_State

input_register_config :: proc() {
	config_register_section("keybindings", &keybindings)
}

input_init :: proc() {
	rl.SetExitKey(.KEY_NULL)
}

raw_text_buffer: ^strings.Builder

// The caller owns the builder. Pass nil to detach.
input_set_raw_text_buffer :: proc(buffer: ^strings.Builder) {
	raw_text_buffer = buffer
}

input_fill_raw_text_buffer :: proc(buffer: ^strings.Builder) {
	for char := rl.GetCharPressed(); char != 0; char = rl.GetCharPressed() {
		strings.write_rune(buffer, char)
	}
	if rl.IsKeyPressed(.BACKSPACE) || rl.IsKeyPressedRepeat(.BACKSPACE) {
		strings.pop_rune(buffer)
	}
}

input_handle_digital_axis :: proc(inc_bind: Keybind, dec_bind: Keybind, ptr: ^f32) {
	inc: bool
	dec: bool

	switch bind in inc_bind {
	case rl.KeyboardKey:
		inc = rl.IsKeyDown(bind)
	case [1]rl.KeyboardKey:
		inc = rl.IsKeyDown(bind[0])
	case [2]rl.KeyboardKey:
		inc = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1])
	case [3]rl.KeyboardKey:
		inc = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1]) || rl.IsKeyDown(bind[2])
	}

	switch bind in dec_bind {
	case rl.KeyboardKey:
		dec = rl.IsKeyDown(bind)
	case [1]rl.KeyboardKey:
		dec = rl.IsKeyDown(bind[0])
	case [2]rl.KeyboardKey:
		dec = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1])
	case [3]rl.KeyboardKey:
		dec = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1]) || rl.IsKeyDown(bind[2])
	}

	ptr^ = inc ? 1.0 : 0.0
	ptr^ += dec ? -1.0 : 0.0
}

input_handle_key_pressed :: proc(bind: Keybind, ptr: ^bool) {
	pressed: bool

	switch bind in bind {
	case rl.KeyboardKey:
		pressed = rl.IsKeyPressed(bind)
	case [1]rl.KeyboardKey:
		pressed = rl.IsKeyPressed(bind[0])
	case [2]rl.KeyboardKey:
		pressed = rl.IsKeyPressed(bind[0]) || rl.IsKeyPressed(bind[1])
	case [3]rl.KeyboardKey:
		pressed = rl.IsKeyPressed(bind[0]) || rl.IsKeyPressed(bind[1]) || rl.IsKeyPressed(bind[2])
	}

	ptr^ = pressed
}

input_handle_key_held :: proc(bind: Keybind, ptr: ^bool) {
	held: bool

	switch bind in bind {
	case rl.KeyboardKey:
		held = rl.IsKeyDown(bind)
	case [1]rl.KeyboardKey:
		held = rl.IsKeyDown(bind[0])
	case [2]rl.KeyboardKey:
		held = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1])
	case [3]rl.KeyboardKey:
		held = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1]) || rl.IsKeyDown(bind[2])
	}

	ptr^ = held
}

input_update :: proc() {
	if input.raw {
		// Raw mode
		{
			// Key pressed
			mappings := []struct {
				bind: Keybind,
				ptr:  ^bool,
			} {


				// only allow the toggle console in raw mode
				// {keybindings.toggle_console, &input.toggle_console},
				{rl.KeyboardKey.ESCAPE, &input.toggle_console},
				{rl.KeyboardKey.ENTER, &input.submit},
				//
			}

			for mapping in mappings {
				input_handle_key_pressed(mapping.bind, mapping.ptr)
			}
		}

		// Skip on the closing frame so the toggle key's own rune stays out of the buffer.
		if raw_text_buffer != nil && !input.toggle_console {
			input_fill_raw_text_buffer(raw_text_buffer)
		}
	} else {
		// Baked mode
		{
			// Digital axis
			mappings := []struct {
				inc_bind: Keybind,
				dec_bind: Keybind,
				ptr:      ^f32,
			} {
				{keybindings.move_right, keybindings.move_left, &input.move[0]},
				{keybindings.move_down, keybindings.move_up, &input.move[1]},
				//
			}

			for mapping in mappings {
				input_handle_digital_axis(mapping.inc_bind, mapping.dec_bind, mapping.ptr)
			}
		}

		{
			// Key pressed
			mappings := []struct {
				bind: Keybind,
				ptr:  ^bool,
			} {
				{keybindings.action, &input.action},
				{keybindings.quit, &input.quit},
				{keybindings.toggle_console, &input.toggle_console},
				{rl.KeyboardKey.ENTER, &input.submit},
				//
			}

			for mapping in mappings {
				input_handle_key_pressed(mapping.bind, mapping.ptr)
			}
		}

		{
			// Key held
			mappings := []struct {
				bind: Keybind,
				ptr:  ^bool,
			} {
				{keybindings.action, &input.action_held},
				//
			}

			for mapping in mappings {
				input_handle_key_held(mapping.bind, mapping.ptr)
			}
		}
	}

	if input.toggle_console {
		input.raw = !input.raw
	}
}
