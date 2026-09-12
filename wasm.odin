// The plugin system across all plugins: one wasmtime engine, one linker with the host
// functions defined once, and the list of loaded plugins. Everything about a single
// plugin is in wasm-plugin.odin; the libm shims every plugin links are in
// wasm-libm-shims.odin.
package odin_game

import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"

Wasm :: struct {
	engine:  ^wasm.Engine,
	linker:  ^wasmtime.Linker, // shared by every plugin, so imports are defined once
	plugins: [dynamic]Plugin,
}

wasm_state: Wasm

// Creates the shared runtime on first use, then loads every plugin afresh. Called at
// startup and again on the reload key.
wasm_init :: proc() {
	if wasm_state.engine == nil {
		wasm_state.engine = wasm.engine_new()
		wasm_state.linker = wasmtime.linker_new(wasm_state.engine)
		if !wasm_define_host_functions(
			wasm_state.linker,
			game_host_functions,
			libm_host_functions,
		) {
			wasm_exit()
			return
		}
	}

	wasm_unload_plugins()
	// for filename in plugin_filenames {
	// 	plugin: Plugin
	// 	if wasm_plugin_load(&plugin, wasm_state.engine, wasm_state.linker, filename) {
	// 		append(&wasm_state.plugins, plugin)
	// 	}
	// }
}

wasm_load_plugin :: proc(path: string) {
	plugin: Plugin
	if wasm_plugin_load(&plugin, wasm_state.engine, wasm_state.linker, path) {
		append(&wasm_state.plugins, plugin)
	}

}

wasm_update :: proc(delta_time: f32) {
	for &plugin in wasm_state.plugins {
		wasm_plugin_update(&plugin, delta_time)
	}
}

wasm_draw :: proc() {
	for &plugin in wasm_state.plugins {
		wasm_plugin_draw(&plugin)
	}
}

wasm_exit :: proc() {
	wasm_unload_plugins()
	delete(wasm_state.plugins)
	if wasm_state.linker != nil {
		wasmtime.linker_delete(wasm_state.linker)
	}
	if wasm_state.engine != nil {
		wasm.engine_delete(wasm_state.engine)
	}
	wasm_state = {}
}

wasm_unload_plugins :: proc() {
	for &plugin in wasm_state.plugins {
		wasm_plugin_unload(&plugin)
	}
	clear(&wasm_state.plugins)
}

// Registers every host function from the tables in the linker, once for all plugins.
wasm_define_host_functions :: proc(linker: ^wasmtime.Linker, tables: ..[]Host_Function) -> bool {
	for table in tables {
		for function in table {
			if !wasm_define_host_function(linker, function) {
				return false
			}
		}
	}
	return true
}

wasm_define_host_function :: proc(linker: ^wasmtime.Linker, function: Host_Function) -> bool {
	error := wasmtime.linker_define_host_function(
		linker,
		function.module,
		function.name,
		function.params,
		function.results,
		function.callback,
		function.data,
	)
	if error != nil {
		warning(
			"Failed to define host function '{}': {}",
			function.name,
			wasmtime.take_error_message(error, context.temp_allocator),
		)
		return false
	}
	return true
}
