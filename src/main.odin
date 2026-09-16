package heimdall

import "./log"
import "./plugins"
import rl "vendor:raylib"

// Plugins to load, in the order they are updated and drawn.
plugin_filenames := []string{"plugin/build/plugin.wasm", "plugin/build/plugin2.wasm"}

second_plugin_loaded: bool

background_color := rl.DARKGREEN

init_window :: proc() {
}

init_systems :: proc() {
	render_init()
	log.init()
	plugins.init()
	if !plugins.define_host_functions(plugins.state.linker, game_host_functions, libm_host_functions) {
		plugins.exit()
	}
	input_init()
	player_init()
	plugins.load_plugin(plugin_filenames[0])
}

update :: proc() {
	input_update()
	player_update()
	plugins.update(rl.GetFrameTime())
	if rl.GetTime() > 1.0 && !second_plugin_loaded {
		plugins.load_plugin(plugin_filenames[1])
		second_plugin_loaded = true
	}
}

draw :: proc() {
	render_begin()
	player_draw()
	plugins.draw()
	render_end()
}

exit :: proc() {
	input_save_keybindings()
	plugins.exit()
}

main :: proc() {
	init_window()
	init_systems()
	log.debug("hello world")

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
			log.debug("console toggled: {:v}", console)
		}
	}

	exit()
}
