package heimdall

import cmd_fps "./cmd/fps"
import cmd_fullscreen "./cmd/fullscreen"
import cmd_help "./cmd/help"
import cmd_render "./cmd/render"
import cmd_vsync "./cmd/vsync"
import "./config"
import "./console"
import "./input"
import "./flags_helpers"
import "./json_marshaler"
import "./log"
import "./player"
import "./render"
import "./wasm"
import "./wasm_host_procs"
import "./wasm_libm_shims"
import rl "vendor:raylib"

plugin_filenames := []string{"plugin/build/plugin.wasm", "plugin/build/plugin2.wasm"}

second_plugin_loaded: bool

init_systems :: proc() {
	// log
	log.init()
	console.init()

	// config
	input.register_config()
	render.register_config()
	config.init()

	// commands
	flags_helpers.init()
	cmd_fps.init()
	cmd_fullscreen.init()
	cmd_help.init()
	cmd_render.init()
	cmd_vsync.init()

	// window
	render.init() // sets up the window

	// plugin vm
	wasm.init()
	if !wasm.define_host_functions(wasm.state.linker, wasm_host_procs.host_functions, wasm_libm_shims.host_functions) {
		wasm.exit()
	}

	// game
	input.init()
	player.init()

	// plugins
	wasm.load_plugin(plugin_filenames[0])
}

update :: proc() {
	console.update()
	config.update()
	input.update()
	player.update()
	wasm.update(rl.GetFrameTime())
	if !second_plugin_loaded && rl.GetTime() > 1.0 {
		wasm.load_plugin(plugin_filenames[1])
		second_plugin_loaded = true
	}
}

draw :: proc() {
	render.begin()
	player.draw()
	wasm.draw()
	console.draw()
	render.end()
}

exit :: proc() {
	// input_save_keybindings()
	wasm.exit()
	// render_exit()
	config.exit()
}

main :: proc() {
	json_marshaler.register_float_marshalers()

	init_systems()
	log.debug("hello world")

	for !rl.WindowShouldClose() {
		update()
		draw()

		if input.state.quit {
			rl.CloseWindow()
		}
	}

	exit()

	json_marshaler.unregister_float_marshalers()
}
