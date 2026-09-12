package odin_game

import "base:runtime"
import "core:c"

import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"
import rl "vendor:raylib"

// A procedure plugins can import as module.name. data reaches the callback as env.
Host_Function :: struct {
	module:   string,
	name:     string,
	params:   []wasm.Valkind,
	results:  []wasm.Valkind,
	callback: wasmtime.Func_Callback,
	data:     rawptr,
}

// The game API under the "host" module, one entry per declaration in module/waylib.
// Wasm passes structs and strings by pointer, so those arguments arrive as i32 offsets.
game_host_functions := []Host_Function {
	{"host", "log", {.I32, .I32}, {}, wasm_host_trace_log, nil},
	{"host", "DrawRectangleV", {.I32, .I32, .I32}, {}, wasm_host_draw_rectangle_v, nil},
}

wasm_host_trace_log :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()
	message, ok := wasm_plugin_guest_string(caller, args[1].of.i32)
	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}
	log(rl.TraceLogLevel(args[0].of.i32), "[plugin] {}", message)
	return nil
}

wasm_host_draw_rectangle_v :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()
	position, ok_position := wasm_plugin_guest_value(caller, args[0].of.i32, rl.Vector2)
	size, ok_size := wasm_plugin_guest_value(caller, args[1].of.i32, rl.Vector2)
	color, ok_color := wasm_plugin_guest_value(caller, args[2].of.i32, rl.Color)
	if !(ok_position && ok_size && ok_color) {
		return wasmtime.trap_from_string("DrawRectangleV: argument out of bounds")
	}
	rl.DrawRectangleV(position, size, color)
	return nil
}
