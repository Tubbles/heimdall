package heimdall

import "./log"
import "core:encoding/json"
import "core:os"
import "core:slice"

import rl "vendor:raylib"

JSON_SPEC :: json.Specification.SJSON
KEYBINDINGS_FILENAME :: "keybindings.sjson"

Keybind :: union {
	rl.KeyboardKey,
	[2]rl.KeyboardKey,
	[3]rl.KeyboardKey,
}

Keybindings :: struct {
	up:             Keybind,
	left:           Keybind,
	down:           Keybind,
	right:          Keybind,
	action:         Keybind,
	quit:           Keybind,
	reload:         Keybind,
	toggle_console: Keybind,
}

keybindings := Keybindings {
	up             = ([2]rl.KeyboardKey){rl.KeyboardKey.W, rl.KeyboardKey.UP},
	left           = ([2]rl.KeyboardKey){rl.KeyboardKey.A, rl.KeyboardKey.LEFT},
	down           = ([2]rl.KeyboardKey){rl.KeyboardKey.S, rl.KeyboardKey.DOWN},
	right          = ([2]rl.KeyboardKey){rl.KeyboardKey.D, rl.KeyboardKey.RIGHT},
	action         = ([2]rl.KeyboardKey){rl.KeyboardKey.E, rl.KeyboardKey.SPACE},
	quit           = ([2]rl.KeyboardKey){rl.KeyboardKey.Q, rl.KeyboardKey.ESCAPE},
	reload         = rl.KeyboardKey.R,
	toggle_console = rl.KeyboardKey.GRAVE,
}

Input_State :: struct {
	move:           [2]f32, // -1..1 on each axis, [0] = horizontal, [1] = vertical
	action:         bool,
	action_held:    bool,
	quit:           bool,
	reload:         bool,
	toggle_console: bool,
}

input: Input_State

input_init :: proc() {
	rl.SetExitKey(.KEY_NULL)
	input_load_keybindings()
}

input_load_keybindings :: proc() {
	if json_data, err := os.read_entire_file(KEYBINDINGS_FILENAME, context.temp_allocator);
	   err == nil {
		if err := json.unmarshal(json_data, &keybindings, spec = JSON_SPEC); err == nil {
			log.debug("Loaded keybindings: {:v}", keybindings)
		} else {
			log.warning("Failed to unmarshal JSON! {:v}", err)
		}
	} else {
		log.warning("Failed to read keybindings! {:v}", err)
	}
}

input_save_keybindings :: proc() {
	opt: json.Marshal_Options = {
		spec           = JSON_SPEC,
		pretty         = true,
		use_enum_names = true,
	}

	json_data, marshal_err := json.marshal(
		keybindings,
		opt = opt,
		allocator = context.temp_allocator,
	)
	if marshal_err != nil {
		log.warning("Couldn't marshal struct! {:v}", marshal_err)
		return
	}

	// append a newline
	json_data = slice.concatenate([][]byte{json_data, transmute([]byte)string("\n")})

	// skip the write if the existing file already matches exactly what we would write,
	// so we don't touch the file needlessly and trigger eg inotify watchers.
	// a missing or unreadable file falls through to the write.
	existing_data, read_err := os.read_entire_file(KEYBINDINGS_FILENAME, context.temp_allocator)
	if read_err == nil && string(existing_data) == string(json_data) {
		return
	}

	if write_err := os.write_entire_file(KEYBINDINGS_FILENAME, json_data); write_err != nil {
		log.warning("Couldn't write file! {:v}", write_err)
	}
}

input_handle_digital_axis :: proc(inc_bind: Keybind, dec_bind: Keybind, ptr: ^f32) {
	inc: bool
	dec: bool

	switch bind in inc_bind {
	case rl.KeyboardKey:
		inc = rl.IsKeyDown(bind)
	case [2]rl.KeyboardKey:
		inc = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1])
	case [3]rl.KeyboardKey:
		inc = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1]) || rl.IsKeyDown(bind[2])
	}

	switch bind in dec_bind {
	case rl.KeyboardKey:
		dec = rl.IsKeyDown(bind)
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
	case [2]rl.KeyboardKey:
		held = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1])
	case [3]rl.KeyboardKey:
		held = rl.IsKeyDown(bind[0]) || rl.IsKeyDown(bind[1]) || rl.IsKeyDown(bind[2])
	}

	ptr^ = held
}

input_update :: proc() {
	// Digital axis
	{
		mappings := []struct {
			inc_bind: Keybind,
			dec_bind: Keybind,
			ptr:      ^f32,
		} {
			{keybindings.right, keybindings.left, &input.move[0]},
			{keybindings.down, keybindings.up, &input.move[1]},
		}

		for mapping in mappings {
			input_handle_digital_axis(mapping.inc_bind, mapping.dec_bind, mapping.ptr)
		}
	}

	// Key pressed
	{
		mappings := []struct {
			bind: Keybind,
			ptr:  ^bool,
		} {
			{keybindings.action, &input.action},
			{keybindings.quit, &input.quit},
			{keybindings.reload, &input.reload},
			{keybindings.toggle_console, &input.toggle_console},
		}

		for mapping in mappings {
			input_handle_key_pressed(mapping.bind, mapping.ptr)
		}
	}

	// Key held
	{
		mappings := []struct {
			bind: Keybind,
			ptr:  ^bool,
		}{{keybindings.action, &input.action_held}}

		for mapping in mappings {
			input_handle_key_held(mapping.bind, mapping.ptr)
		}
	}

}
