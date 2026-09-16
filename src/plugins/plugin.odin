// One plugin: its own wasmtime store, module and instance, the exports the engine calls,
// and the helpers host functions use to read the plugin's memory. The game API a plugin
// imports, declared in module/waylib, is implemented at the bottom. wasm.odin owns the
// engine and linker these build on and the list of plugins.
package plugins

import "../log"
import "base:runtime"
import "core:c"
import "core:mem"
import "core:os"

import wasm "module:wasm-bindings"
import wasmtime "module:wasmtime-bindings"

Plugin :: struct {
	path:     string,
	store:    ^wasmtime.Store,
	ctx:      ^wasmtime.Context,
	module:   ^wasmtime.Module,
	instance: wasmtime.Instance,
	init:     wasmtime.Func,
	update:   wasmtime.Func,
	draw:     wasmtime.Func,
	loaded:   bool, // false until instantiated, and again after a trap
}

// Reads, compiles, instantiates and initialises the plugin at path. The engine compiles
// it and the linker supplies its imports; the plugin gets a store of its own so it can be
// unloaded without touching the others.
load :: proc(
	plugin: ^Plugin,
	engine: ^wasm.Engine,
	linker: ^wasmtime.Linker,
	path: string,
) -> bool {
	wasm_bytes, read_error := os.read_entire_file(path, context.temp_allocator)
	if read_error != nil {
		log.warning("Failed to read plugin '{}': {}", path, read_error)
		return false
	}

	plugin.path = path
	plugin.store = wasmtime.store_new(engine, nil, nil)
	plugin.ctx = wasmtime.store_context(plugin.store)

	ok :=
		compile(plugin, engine, wasm_bytes) &&
		instantiate(plugin, linker) &&
		find_exports(plugin) &&
		call(plugin, &plugin.init, {})
	if !ok {
		unload(plugin)
	}
	return ok
}

compile :: proc(plugin: ^Plugin, engine: ^wasm.Engine, wasm_bytes: []byte) -> bool {
	error := wasmtime.module_new(
		engine,
		raw_data(wasm_bytes),
		c.size_t(len(wasm_bytes)),
		&plugin.module,
	)
	if error != nil {
		log.warning(
			"Failed to compile plugin '{}': {}",
			plugin.path,
			wasmtime.take_error_message(error, context.temp_allocator),
		)
		return false
	}
	return true
}

instantiate :: proc(plugin: ^Plugin, linker: ^wasmtime.Linker) -> bool {
	trap: ^wasm.Trap
	error := wasmtime.linker_instantiate(
		linker,
		plugin.ctx,
		plugin.module,
		&plugin.instance,
		&trap,
	)
	if error != nil {
		log.warning(
			"Failed to instantiate plugin '{}': {}",
			plugin.path,
			wasmtime.take_error_message(error, context.temp_allocator),
		)
		return false
	}
	if trap != nil {
		log.warning(
			"Plugin '{}' trapped during instantiation: {}",
			plugin.path,
			wasm.take_trap_message(trap, context.temp_allocator),
		)
		return false
	}
	plugin.loaded = true
	return true
}

find_exports :: proc(plugin: ^Plugin) -> bool {
	entries := [?]struct {
		name: string,
		func: ^wasmtime.Func,
	}{{"init", &plugin.init}, {"update", &plugin.update}, {"draw", &plugin.draw}}

	for entry in entries {
		found: bool
		entry.func^, found = wasmtime.instance_func(plugin.ctx, &plugin.instance, entry.name)
		if !found {
			log.warning("Plugin '{}' does not export '{}'", plugin.path, entry.name)
			return false
		}
	}
	return true
}

unload :: proc(plugin: ^Plugin) {
	if plugin.module != nil {
		wasmtime.module_delete(plugin.module)
	}
	if plugin.store != nil {
		wasmtime.store_delete(plugin.store)
	}
	plugin^ = {}
}

// Calls an exported plugin procedure that returns nothing. A trap or error disables the
// plugin until the next reload so a broken plugin cannot warn on every frame.
call :: proc(plugin: ^Plugin, function: ^wasmtime.Func, args: []wasmtime.Val) -> bool {
	if !plugin.loaded {
		return false
	}
	trap: ^wasm.Trap
	error := wasmtime.func_call(
		plugin.ctx,
		function,
		raw_data(args),
		c.size_t(len(args)),
		nil,
		0,
		&trap,
	)
	if error != nil {
		log.warning(
			"Plugin '{}' call failed: {}",
			plugin.path,
			wasmtime.take_error_message(error, context.temp_allocator),
		)
		plugin.loaded = false
		return false
	}
	if trap != nil {
		log.warning(
			"Plugin '{}' trapped: {}",
			plugin.path,
			wasm.take_trap_message(trap, context.temp_allocator),
		)
		plugin.loaded = false
		return false
	}
	return true
}

update_plugin :: proc(plugin: ^Plugin, delta_time: f32) {
	call(plugin, &plugin.update, {wasmtime.val_f32(delta_time)})
}

draw_plugin :: proc(plugin: ^Plugin) {
	call(plugin, &plugin.draw, {})
}

// A bounds-checked view of a buffer the plugin passed as pointer and length.
guest_bytes :: proc(
	caller: ^wasmtime.Caller,
	pointer, length: i32,
) -> (
	bytes: []byte,
	ok: bool,
) {
	memory := wasmtime.caller_memory(caller) or_return
	return wasm.guest_slice(
		wasmtime.memory_bytes(wasmtime.caller_context(caller), &memory),
		pointer,
		length,
	)
}

// Reads a value the plugin passed by pointer, which is how wasm passes structs. Both
// sides are little endian and the raylib types have the same layout in both.
guest_value :: proc(
	caller: ^wasmtime.Caller,
	pointer: i32,
	$Type: typeid,
) -> (
	value: Type,
	ok: bool,
) {
	bytes := guest_bytes(caller, pointer, i32(size_of(Type))) or_return
	mem.copy_non_overlapping(&value, raw_data(bytes), size_of(Type))
	return value, true
}

// An Odin string header as laid out in the plugin's 32-bit memory.
Guest_String :: struct {
	data:   u32,
	length: u32,
}

// Reads a string the plugin passed by pointer.
guest_string :: proc(
	caller: ^wasmtime.Caller,
	pointer: i32,
) -> (
	text: string,
	ok: bool,
) {
	header := guest_value(caller, pointer, Guest_String) or_return
	bytes := guest_bytes(caller, i32(header.data), i32(header.length)) or_return
	return string(bytes), true
}
