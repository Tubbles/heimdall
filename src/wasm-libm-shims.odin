// libm for plugins. On non-JS targets core:math lowers sin, cos, exp and pow to LLVM
// intrinsics (core/math/math_basic.odin) and the wasm backend turns those into imports
// from the "env" module. Everything else in core:math is plain Odin. Odin's own odin.js
// supplies the same functions for the browser, here the engine does.
package heimdall

import "core:c"
import "core:math"
import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"

// The callbacks below get the math procedure to call through env.
libm_host_functions := []Wasm_Host_Function {
	{"env", "sinf", {.F32}, {.F32}, libm_unary_f32, rawptr(math.sin_f32)},
	{"env", "cosf", {.F32}, {.F32}, libm_unary_f32, rawptr(math.cos_f32)},
	{"env", "expf", {.F32}, {.F32}, libm_unary_f32, rawptr(math.exp_f32)},
	{"env", "powf", {.F32, .F32}, {.F32}, libm_binary_f32, rawptr(math.pow_f32)},
	{"env", "sin", {.F64}, {.F64}, libm_unary_f64, rawptr(math.sin_f64)},
	{"env", "cos", {.F64}, {.F64}, libm_unary_f64, rawptr(math.cos_f64)},
	{"env", "exp", {.F64}, {.F64}, libm_unary_f64, rawptr(math.exp_f64)},
	{"env", "pow", {.F64, .F64}, {.F64}, libm_binary_f64, rawptr(math.pow_f64)},
}

Libm_Unary_F32 :: #type proc "contextless" (x: f32) -> f32
Libm_Binary_F32 :: #type proc "contextless" (x, y: f32) -> f32
Libm_Unary_F64 :: #type proc "contextless" (x: f64) -> f64
Libm_Binary_F64 :: #type proc "contextless" (x, y: f64) -> f64

libm_unary_f32 :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	function := cast(Libm_Unary_F32)env
	results[0] = wasmtime.val_f32(function(args[0].of.f32))
	return nil
}

libm_binary_f32 :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	function := cast(Libm_Binary_F32)env
	results[0] = wasmtime.val_f32(function(args[0].of.f32, args[1].of.f32))
	return nil
}

libm_unary_f64 :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	function := cast(Libm_Unary_F64)env
	results[0] = wasmtime.val_f64(function(args[0].of.f64))
	return nil
}

libm_binary_f64 :: proc "c" (
	env: rawptr,
	caller: ^wasmtime.Caller,
	args: [^]wasmtime.Val,
	nargs: c.size_t,
	results: [^]wasmtime.Val,
	nresults: c.size_t,
) -> ^wasm.Trap {
	function := cast(Libm_Binary_F64)env
	results[0] = wasmtime.val_f64(function(args[0].of.f64, args[1].of.f64))
	return nil
}
