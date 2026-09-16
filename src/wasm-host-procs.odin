package heimdall

import "./log"
import "./plugins"
import "base:runtime"
import "core:c"
import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"
import rl "vendor:raylib"

// The game API under the "host" module, one entry per declaration in module/waylib.
// Wasm passes structs and strings by pointer, so those arguments arrive as i32 offsets.
game_host_functions := []plugins.Host_Function {
	{"host", "log", {.I32, .I32}, {}, wasm_host_trace_log, nil},
	{"host", "DrawRectangleV", {.I32, .I32, .I32}, {}, wasm_host_draw_rectangle_v, nil},
	{"host", "set_background_color", {.I32}, {}, wasm_host_set_background_color, nil},
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

	message, ok := plugins.guest_string(caller, args[1].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.log(rl.TraceLogLevel(args[0].of.i32), "[plugin] {}", message)

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

	position, ok_position := plugins.guest_value(caller, args[0].of.i32, rl.Vector2)
	size, ok_size := plugins.guest_value(caller, args[1].of.i32, rl.Vector2)
	color, ok_color := plugins.guest_value(caller, args[2].of.i32, rl.Color)

	if !(ok_position && ok_size && ok_color) {
		return wasmtime.trap_from_string("DrawRectangleV: argument out of bounds")
	}

	rl.DrawRectangleV(position, size, color)

	return nil
}

wasm_host_set_background_color :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	color, ok_color := plugins.guest_value(caller, args[0].of.i32, rl.Color)
	if !(ok_color) {
		return wasmtime.trap_from_string("set_background_color: argument out of bounds")
	}

	background_color = color

	return nil
}
