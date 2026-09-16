package plugins

import "../log"
import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"

Wasm :: struct {
	engine:  ^wasm.Engine,
	linker:  ^wasmtime.Linker, // shared by every plugin, so imports are defined once
	plugins: [dynamic]Plugin,
}

// A procedure plugins can import as module.name.
Host_Function :: struct {
	module:   string,
	name:     string,
	params:   []wasm.Valkind,
	results:  []wasm.Valkind,
	callback: wasmtime.Func_Callback,
	data:     rawptr,
}

state: Wasm

init :: proc() {
	if state.engine == nil {
		state.engine = wasm.engine_new()
		state.linker = wasmtime.linker_new(state.engine)
	}

	unload_plugins()
	// for filename in filenames {
	// 	plugin: Plugin
	// 	if load(&plugin, state.engine, state.linker, filename) {
	// 		append(&state.plugins, plugin)
	// 	}
	// }
}

load_plugin :: proc(path: string) {
	plugin: Plugin
	if load(&plugin, state.engine, state.linker, path) {
		append(&state.plugins, plugin)
	}

}

update :: proc(delta_time: f32) {
	for &plugin in state.plugins {
		update_plugin(&plugin, delta_time)
	}
}

draw :: proc() {
	for &plugin in state.plugins {
		draw_plugin(&plugin)
	}
}

exit :: proc() {
	unload_plugins()
	delete(state.plugins)
	if state.linker != nil {
		wasmtime.linker_delete(state.linker)
	}
	if state.engine != nil {
		wasm.engine_delete(state.engine)
	}
	state = {}
}

unload_plugins :: proc() {
	for &plugin in state.plugins {
		unload(&plugin)
	}
	clear(&state.plugins)
}

// Registers every host function from the tables in the linker, once for all plugins.
define_host_functions :: proc(linker: ^wasmtime.Linker, tables: ..[]Host_Function) -> bool {
	for table in tables {
		for function in table {
			if !define_host_function(linker, function) {
				return false
			}
		}
	}
	return true
}

define_host_function :: proc(linker: ^wasmtime.Linker, function: Host_Function) -> bool {
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
		log.warning(
			"Failed to define host function '{}': {}",
			function.name,
			wasmtime.take_error_message(error, context.temp_allocator),
		)
		return false
	}
	return true
}
