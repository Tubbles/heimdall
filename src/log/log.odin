package heimdall_log

import "core:fmt"
import "core:strings"

import rl "vendor:raylib"

Backend :: proc(logstr: string)

backends: [dynamic]Backend

register_backend :: proc(backend: Backend) {
	append(&backends, backend)
}

init :: proc() {
	rl.SetTraceLogLevel(.DEBUG)
}

write :: proc(level: rl.TraceLogLevel, format: string, args: ..any) {
	string_builder: strings.Builder
	fmt.sbprintf(&string_builder, format, ..args)
	rl.TraceLog(level, "%s", string_builder.buf)
	logstr := fmt.tprintf("[{}] {}", level, strings.to_string(string_builder))
	for backend in backends {
		backend(logstr)
	}
}

trace :: proc(format: string, args: ..any) {
	write(.TRACE, format, ..args)
}

debug :: proc(format: string, args: ..any) {
	write(.DEBUG, format, ..args)
}

info :: proc(format: string, args: ..any) {
	write(.INFO, format, ..args)
}

warning :: proc(format: string, args: ..any) {
	write(.WARNING, format, ..args)
}

error :: proc(format: string, args: ..any) {
	write(.ERROR, format, ..args)
}

fatal :: proc(format: string, args: ..any) {
	write(.FATAL, format, ..args)
}
