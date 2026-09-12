package odin_game

import rl "vendor:raylib"
// import wasm "module:wasm-bindings"
// import wasmtime "module:wasmtime-bindings"

// Plugins to load, in the order they are updated and drawn.
plugin_filenames := []string{"plugin/build/plugin.wasm", "plugin/build/plugin2.wasm"}

second_plugin_loaded: bool

init_window :: proc() {
	rl.InitWindow(500, 500, "Odin game")
	rl.ToggleFullscreen()
	rl.HideCursor()
	rl.SetExitKey(.KEY_NULL)
	rl.SetTraceLogLevel(.DEBUG)
}

init_systems :: proc() {
	wasm_init()
	input_load_keybindings()
	player_init()
	wasm_load_plugin(plugin_filenames[0])
}

update :: proc() {
	input_update()
	player_update()
	wasm_update(rl.GetFrameTime())
	if rl.GetTime() > 1.0 && !second_plugin_loaded {
		wasm_load_plugin(plugin_filenames[1])
		second_plugin_loaded = true
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.DARKGREEN)
	player_draw()
	wasm_draw()
	rl.EndDrawing()
}

exit :: proc() {
	input_save_keybindings()
	wasm_exit()
}

main :: proc() {
	init_window()
	init_systems()
	debug("hello world")

	for !rl.WindowShouldClose() {
		update()
		draw()

		if input.quit {
			rl.CloseWindow()
		}

		if input.reload {
			init_systems()
		}

		if input.toggle_console {
			console = !console
			debug("console toggled: {:v}", console)
		}
	}

	exit()
}
