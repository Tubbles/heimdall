package heimdall_flags_helpers

import "core:flags"
import "core:strings"

usage_text :: proc(args_type: typeid, program: string) -> string {
	builder := strings.builder_make()
	flags.write_usage(strings.to_writer(&builder), args_type, program)
	return strings.trim_right_space(strings.to_string(builder))
}
