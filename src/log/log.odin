package heimdall_log

import "core:fmt"
import "core:strings"

import rl "vendor:raylib"

init :: proc() {
	rl.SetTraceLogLevel(.DEBUG)
}

log :: proc(level: rl.TraceLogLevel, format: string, args: ..any) {
	string_builder: strings.Builder
	fmt.sbprintf(&string_builder, format, ..args)
	rl.TraceLog(level, "%s", string_builder.buf)
}

debug :: proc(format: string, args: ..any) {
	log(.DEBUG, format, ..args)
}

warning :: proc(format: string, args: ..any) {
	log(.WARNING, format, ..args)
}
