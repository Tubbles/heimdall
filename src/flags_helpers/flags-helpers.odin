package heimdall_flags_helpers

import "core:flags"
import "core:reflect"
import "core:strings"

// The usage tag is a string literal in the binary, not an allocation
field_usage :: proc(args_type: typeid, field_name: string) -> string {
	field := reflect.struct_field_by_name(args_type, field_name)
	usage, _ := reflect.struct_tag_lookup(field.tag, flags.TAG_USAGE)
	return usage
}

usage_text :: proc(args_type: typeid, program: string) -> string {
	builder := strings.builder_make()
	flags.write_usage(strings.to_writer(&builder), args_type, program)
	return strings.trim_right_space(strings.to_string(builder))
}
