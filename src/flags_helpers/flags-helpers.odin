package heimdall_flags_helpers

import "../console"
import "base:runtime"
import "core:flags"
import "core:strconv"
import "core:strings"

Toggle :: distinct bool

usage_text :: proc(args_type: typeid, program: string) -> string {
	builder := strings.builder_make()
	flags.write_usage(strings.to_writer(&builder), args_type, program)
	return strings.trim_right_space(strings.to_string(builder))
}

parse :: proc(model: ^$T, args: []string, help_text: string) -> (ok: bool) {
	if parse_result := flags.parse(model, args); parse_result != nil {
		if parse_error, ok := parse_result.(flags.Parse_Error); ok {
			console.printfln("%s", parse_error.message)
		} else if open_file_error, ok := parse_result.(flags.Open_File_Error); ok {
			console.printfln("%s: %v", open_file_error.filename, open_file_error.errno)
		} else if validation_error, ok := parse_result.(flags.Validation_Error); ok {
			console.printfln("%s", validation_error.message)
		}
		console.printfln("%s", help_text)
		return false
	}

	return true
}

parse_toggle :: proc(text: string) -> (value: bool, ok: bool) {
	switch text {
	case "on":
		return true, true
	case "off":
		return false, true
	}
	return strconv.parse_bool(text)
}

type_setter :: proc(
	data: rawptr,
	data_type: typeid,
	unparsed_value: string,
	args_tag: string,
) -> (
	error: string,
	handled: bool,
	alloc_error: runtime.Allocator_Error,
) {
	if data_type != Toggle {
		return
	}
	value, ok := parse_toggle(unparsed_value)
	if !ok {
		return "Expected on/off, true/false or 1/0.", true, nil
	}
	(^Toggle)(data)^ = Toggle(value)
	return "", true, nil
}

init :: proc() {
	flags.register_type_setter(type_setter)
}
