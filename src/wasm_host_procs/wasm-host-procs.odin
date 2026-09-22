package heimdall_wasm_host_procs

import "../log"
import "../plugin"
import "../render"
import heimdall_wasm "../wasm"
import "base:runtime"
import "core:c"
import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"
import rl "vendor:raylib"

// The game API under the "host" module, one entry per declaration in module/waylib.
// Wasm passes structs and strings by pointer, so those arguments arrive as i32 offsets.
host_functions := []heimdall_wasm.Host_Function {
	{"heimdall", "trace", {.I32}, {}, wasm_host_trace_trace, nil},
	{"heimdall", "debug", {.I32}, {}, wasm_host_trace_debug, nil},
	{"heimdall", "info", {.I32}, {}, wasm_host_trace_info, nil},
	{"heimdall", "warning", {.I32}, {}, wasm_host_trace_warning, nil},
	{"heimdall", "error", {.I32}, {}, wasm_host_trace_error, nil},
	{"heimdall", "fatal", {.I32}, {}, wasm_host_trace_fatal, nil},
	{"heimdall", "DrawRectangleV", {.I32, .I32, .I32}, {}, wasm_host_draw_rectangle_v, nil},
	{"heimdall", "set_background_color", {.I32}, {}, wasm_host_set_background_color, nil},
}

wasm_host_trace_trace :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	message, ok := plugin.guest_string(caller, args[0].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.trace("[plugin] {}", message)

	return nil
}

wasm_host_trace_debug :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	message, ok := plugin.guest_string(caller, args[0].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.debug("[plugin] {}", message)

	return nil
}

wasm_host_trace_info :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	message, ok := plugin.guest_string(caller, args[0].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.info("[plugin] {}", message)

	return nil
}

wasm_host_trace_warning :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	message, ok := plugin.guest_string(caller, args[0].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.warning("[plugin] {}", message)

	return nil
}

wasm_host_trace_error :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	message, ok := plugin.guest_string(caller, args[0].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.error("[plugin] {}", message)

	return nil
}

wasm_host_trace_fatal :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	context = runtime.default_context()

	message, ok := plugin.guest_string(caller, args[0].of.i32)

	if !ok {
		return wasmtime.trap_from_string("log: message out of bounds")
	}

	log.fatal("[plugin] {}", message)

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

	position, ok_position := plugin.guest_value(caller, args[0].of.i32, rl.Vector2)
	size, ok_size := plugin.guest_value(caller, args[1].of.i32, rl.Vector2)
	color, ok_color := plugin.guest_value(caller, args[2].of.i32, rl.Color)

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

	color, ok_color := plugin.guest_value(caller, args[0].of.i32, rl.Color)
	if !(ok_color) {
		return wasmtime.trap_from_string("set_background_color: argument out of bounds")
	}

	render.background_color = color

	return nil
}
