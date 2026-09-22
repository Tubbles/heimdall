package heimdall

import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"

Wasm :: struct {
	engine:  ^wasm.Engine,
	linker:  ^wasmtime.Linker, // shared by every plugin, so imports are defined once
	plugins: [dynamic]Plugin,
}

// A procedure plugins can import as module.name.
Wasm_Host_Function :: struct {
	module:   string,
	name:     string,
	params:   []wasm.Valkind,
	results:  []wasm.Valkind,
	callback: wasmtime.Func_Callback,
	data:     rawptr,
}

wasm_state: Wasm

wasm_init :: proc() {
	if wasm_state.engine == nil {
		wasm_state.engine = wasm.engine_new()
		wasm_state.linker = wasmtime.linker_new(wasm_state.engine)
	}

	wasm_unload_plugins()
	// for filename in filenames {
	// 	plugin: Plugin
	// 	if load(&plugin, wasm_state.engine, wasm_state.linker, filename) {
	// 		append(&wasm_state.plugins, plugin)
	// 	}
	// }
}

wasm_load_plugin :: proc(path: string) {
	plugin: Plugin
	if plugin_load(&plugin, wasm_state.engine, wasm_state.linker, path) {
		append(&wasm_state.plugins, plugin)
	}

}

wasm_update :: proc(delta_time: f32) {
	for &plugin in wasm_state.plugins {
		plugin_update(&plugin, delta_time)
	}
}

wasm_draw :: proc() {
	for &plugin in wasm_state.plugins {
		plugin_draw(&plugin)
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
		plugin_unload(&plugin)
	}
	clear(&wasm_state.plugins)
}

// Registers every host function from the tables in the linker, once for all plugins.
wasm_define_host_functions :: proc(linker: ^wasmtime.Linker, tables: ..[]Wasm_Host_Function) -> bool {
	for table in tables {
		for function in table {
			if !wasm_define_host_function(linker, function) {
				return false
			}
		}
	}
	return true
}

wasm_define_host_function :: proc(linker: ^wasmtime.Linker, function: Wasm_Host_Function) -> bool {
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
