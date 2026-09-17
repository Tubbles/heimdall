package heimdall

import "./log"
import "core:encoding/json"
import "core:os"
import "core:slice"

CONFIG_JSON_SPEC :: json.Specification.SJSON

config_load :: proc(filename: string, obj: ^$T) {
	if json_data, err := os.read_entire_file(filename, context.temp_allocator); err == nil {
		if err := json.unmarshal(json_data, obj, spec = CONFIG_JSON_SPEC); err == nil {
			// log.debug("Loaded render_settings: {:v}", render_settings)
		} else {
			log.warning("Failed to unmarshal {:v} JSON! {:v}", filename, err)
		}
	} else {
		log.warning("Failed to read {:v}! {:v}", filename, err)
	}
}

config_save :: proc(filename: string, obj: $T) {
	opt: json.Marshal_Options = {
		spec           = RENDER_JSON_SPEC,
		pretty         = true,
		use_enum_names = true,
	}

	json_data, marshal_err := json.marshal(obj, opt = opt, allocator = context.temp_allocator)
	if marshal_err != nil {
		log.warning("Couldn't marshal {:v} struct! {:v}", filename, marshal_err)
		return
	}

	// append a newline
	json_data = slice.concatenate([][]byte{json_data, transmute([]byte)string("\n")})

	// skip the write if the existing file already matches exactly what we would write,
	// so we don't touch the file needlessly and trigger eg inotify watchers.
	// a missing or unreadable file falls through to the write.
	existing_data, read_err := os.read_entire_file(filename, context.temp_allocator)
	if read_err == nil && string(existing_data) == string(json_data) {
		return
	}

	if write_err := os.write_entire_file(filename, json_data); write_err != nil {
		log.warning("Couldn't write {:v} file! {:v}", filename, write_err)
	}
}
