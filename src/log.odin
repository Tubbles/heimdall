package heimdall

import "core:fmt"
import "core:strings"

import rl "vendor:raylib"

log_init :: proc() {
	rl.SetTraceLogLevel(.DEBUG)
}

log_write :: proc(level: rl.TraceLogLevel, format: string, args: ..any) {
	string_builder: strings.Builder
	fmt.sbprintf(&string_builder, format, ..args)
	rl.TraceLog(level, "%s", string_builder.buf)
	console_write_string(fmt.tprintf("[{}] {}", level, strings.to_string(string_builder)))
}

trace :: proc(format: string, args: ..any) {
	log_write(.TRACE, format, ..args)
}

debug :: proc(format: string, args: ..any) {
	log_write(.DEBUG, format, ..args)
}

info :: proc(format: string, args: ..any) {
	log_write(.INFO, format, ..args)
}

warning :: proc(format: string, args: ..any) {
	log_write(.WARNING, format, ..args)
}

error :: proc(format: string, args: ..any) {
	log_write(.ERROR, format, ..args)
}

fatal :: proc(format: string, args: ..any) {
	log_write(.FATAL, format, ..args)
}
