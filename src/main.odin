package heimdall

import rl "vendor:raylib"

@(private="file")
plugin_filenames := []string{"plugin/build/plugin.wasm", "plugin/build/plugin2.wasm"}

@(private="file")
second_plugin_loaded: bool

background_color := rl.WHITE

init_systems :: proc() {
	console_init()
	log_init()
	input_register_config()
	render_register_config()
	config_init()
	render_init() // sets up the window
	wasm_init()
	if !wasm_define_host_functions(wasm_state.linker, game_host_functions, libm_host_functions) {
		wasm_exit()
	}
	input_init()
	player_init()
	wasm_load_plugin(plugin_filenames[0])
}

update :: proc() {
	console_update()
	config_update()
	input_update()
	player_update()
	wasm_update(rl.GetFrameTime())
	if !second_plugin_loaded && rl.GetTime() > 1.0 {
		wasm_load_plugin(plugin_filenames[1])
		second_plugin_loaded = true
	}
}

draw :: proc() {
	render_begin()
	player_draw()
	wasm_draw()
	console_draw()
	render_end()
}

exit :: proc() {
	// input_save_keybindings()
	wasm_exit()
	// render_exit()
	config_exit()
}

main :: proc() {
	json_register_float_marshalers()

	init_systems()
	debug("hello world")

	for !rl.WindowShouldClose() {
		update()
		draw()

		if input.quit {
			rl.CloseWindow()
		}
	}

	exit()

	json_unregister_float_marshalers()
}
