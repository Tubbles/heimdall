package heimdall_config

import "../log"
import "core:encoding/json"
import "core:hash"
import "core:os"
import "core:strings"
import fsw "module:odin-fsw"
// import "core:testing"

FILENAME :: "heimdall_config.sjson"
PLUGIN_FILENAME :: "heimdall_plugin_config.sjson"
JSON_SPEC :: json.Specification.SJSON

File :: struct {
	sections: [dynamic]Section,
	cfg_path: string,
	watcher:  fsw.Watcher_File,
	watching: bool,
}

global_file: File

// sort_maps_by_key makes the marshaled form of a parsed section deterministic,
// which section_hash relies on (json.Object iteration order is not stable).
opt: json.Marshal_Options = {
	spec             = JSON_SPEC,
	pretty           = true,
	use_enum_names   = true,
	sort_maps_by_key = true,
}

On_Change :: proc(user_data: rawptr)

Section :: struct {
	key:          string,
	target:       rawptr, // the module's live struct (T), decoded into in place
	value_type:   typeid, // T, what json.marshal wants
	pointer_type: typeid, // ^T, what json.unmarshal wants
	on_change:    On_Change, // optional, fired after a changed section was decoded on hot reload
	user_data:    rawptr,
	last_hash:    u64,
}

// Register a typed struct as a top-level section. `target` must outlive the
// config system (a global or long-lived allocation). Fields missing from the
// file keep whatever `target` already holds, so initialise it with defaults.
// `on_change` fires on hot reload only, not on the initial load in
// init: apply the loaded settings in the module's own init instead.
// Registering a key again (e.g. on reload) replaces the earlier entry.
register_section :: proc(key: string, target: ^$T, on_change: On_Change = nil, user_data: rawptr = nil) {
	self := &global_file
	// The `any` values for marshal/unmarshal are built at the point of use.
	// Storing `any(target)` here would capture the address of this proc's
	// `target` parameter, a stack slot that is dead once we return.
	section := Section {
		key          = key,
		target       = target,
		value_type   = typeid_of(T),
		pointer_type = typeid_of(^T),
		on_change    = on_change,
		user_data    = user_data,
	}
	for &existing in self^.sections {
		if existing.key == key {
			existing = section
			return
		}
	}
	append(&self^.sections, section)
}

// Loads the file once and starts watching it. Returns false if watching failed
// (config still loaded; just no hot reload). Safe to call again (e.g. on
// reload): the previous watcher is destroyed first.
init :: proc() -> bool {
	// first init main config file
	if global_file.watching do fsw.destroy(global_file.watcher)
	global_file.cfg_path = FILENAME
	load(&global_file, notify = false)
	save(&global_file) // write back defaults for any missing sections/fields

	err: fsw.Error
	global_file.watcher, err = fsw.watch_file(FILENAME)
	global_file.watching = err == nil
	return global_file.watching
}

exit :: proc() {
	if global_file.watching do fsw.destroy(global_file.watcher)
	global_file.watching = false
	delete(global_file.sections)
	global_file.sections = {}
}

update :: proc() {
	if !global_file.watching do return
	events := fsw.get_events(&global_file.watcher, context.temp_allocator)
	if len(events) > 0 {
		load(&global_file, notify = true)
		// save(&heimdall_file)
	}
}

// Hash of a section's canonical text: the parsed json.Value marshaled with
// `opt`. Load and save both hash this form so they agree on "unchanged".
// Returns 0 if marshaling fails, which just forces a decode on the next load.
section_hash :: proc(v: json.Value) -> u64 {
	bytes, err := json.marshal(v, opt)
	if err != nil do return 0
	defer delete(bytes)
	return hash.fnv64a(bytes)
}

load :: proc(self: ^File, notify: bool) -> bool {
	data, rerr := os.read_entire_file(self^.cfg_path, context.allocator)
	if rerr != nil do return false
	defer delete(data)

	root, err := json.parse(data, spec = JSON_SPEC, parse_integers = true)
	if err != nil do return false // half-written file; next event retries
	defer json.destroy_value(root)

	obj, is_obj := root.(json.Object)
	if !is_obj do return false

	for &section in self^.sections {
		value, present := obj[section.key]
		if !present do continue

		hash := section_hash(value)
		if hash == section.last_hash do continue
		section.last_hash = hash

		bytes, marshal_err := json.marshal(value, opt)
		if marshal_err != nil do continue
		defer delete(bytes)

		if json.unmarshal_any(bytes, any{&section.target, section.pointer_type}, spec = JSON_SPEC) == nil {
			if notify && section.on_change != nil do section.on_change(section.user_data)
		}
	}
	return true
}

save :: proc(self: ^File) -> bool {
	doc := make(json.Object, len(self^.sections))
	defer json.destroy_value(doc)

	for &s in self^.sections {
		bytes, merr := json.marshal(any{s.target, s.value_type}, opt)
		if merr != nil {
			log.error("config: marshal section '{}' failed: {:v}", s.key, merr)
			return false
		}
		defer delete(bytes)

		// parse_integers keeps ints as ints; without it they round-trip as
		// floats and get written back as e.g. `target_fps: 120.0000000000000000`
		v, perr := json.parse(bytes, spec = JSON_SPEC, parse_integers = true)
		if perr != nil {
			log.error("config: re-parse section '{}' failed: {:v}", s.key, perr)
			return false
		}
		s.last_hash = section_hash(v)
		doc[strings.clone(s.key)] = v
	}

	bytes, err := json.marshal(doc, opt)
	if err != nil {
		log.error("config: marshal document failed: {:v}", err)
		return false
	}
	defer delete(bytes)

	if werr := os.write_entire_file(self^.cfg_path, bytes); werr != nil {
		log.error("config: write '{}' failed: {:v}", self^.cfg_path, werr)
		return false
	}
	return true
}

// // Overwrites the stack region a just-returned callee used, so a section
// // registry that captured a stack address (the original segfault) is caught.
//
// test_scribble_stack :: proc(depth: int) {
// 	buffer: [512]uintptr
// 	for &slot in buffer do slot = 0xDEAD_BEEF
// 	if depth > 0 do test_scribble_stack(depth - 1)
// }
//
//
// test_count_change :: proc(user_data: rawptr) {
// 	(^int)(user_data)^ += 1
// }
//
// // One test proc on purpose: the config state is global and the test runner
// // runs test procs in parallel.
// @(test)
// test_config :: proc(t: ^testing.T) {
// 	Section :: struct {
// 		number: int,
// 		flag:   bool,
// 		scale:  f32,
// 	}
// 	section := Section {
// 		number = 1,
// 		flag   = false,
// 		scale  = 1,
// 	}
// 	changes: int
//
// 	temp_dir, dir_err := os.temp_dir(context.temp_allocator)
// 	testing.expect(t, dir_err == nil)
// 	path := strings.concatenate({temp_dir, "/heimdall_config_test.sjson"}, context.temp_allocator)
// 	defer os.remove(path)
// 	testing.expect(t, os.write_entire_file(path, "test: { number: 42, flag: true, scale: 0.1 }") == nil)
//
// 	// init decodes the file into the registered struct without notifying
// 	register_section("test", &section, test_count_change, &changes)
// 	test_scribble_stack(8)
// 	init(path)
// 	testing.expect_value(t, section.number, 42)
// 	testing.expect_value(t, section.flag, true)
// 	testing.expect_value(t, section.scale, 0.1)
// 	testing.expect_value(t, changes, 0)
//
// 	// floats are written back in their shortest form
// 	written, read_err := os.read_entire_file(path, context.temp_allocator)
// 	testing.expect(t, read_err == nil)
// 	testing.expect(t, strings.contains(string(written), "scale: 0.1\n"))
//
// 	// the file as written back by init counts as unchanged
// 	load(notify = true)
// 	testing.expect_value(t, changes, 0)
//
// 	// a changed file notifies once
// 	testing.expect(t, os.write_entire_file(path, "test: { number: 43, flag: true }") == nil)
// 	load(notify = true)
// 	load(notify = true)
// 	testing.expect_value(t, section.number, 43)
// 	testing.expect_value(t, changes, 1)
//
// 	// re-registration and re-init (reload) replace instead of duplicate
// 	register_section("test", &section, test_count_change, &changes)
// 	init(path)
// 	testing.expect_value(t, len(sections), 1)
// 	testing.expect_value(t, changes, 1)
//
// 	exit()
// 	testing.expect_value(t, len(sections), 0)
// 	testing.expect_value(t, watching, false)
// }
