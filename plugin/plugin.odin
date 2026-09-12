// Example game plugin, built to WebAssembly by build.sh and loaded by plugin_host.odin.
//
// The engine calls the exported procedures and the plugin talks back through
// module:waylib, a raylib-shaped API the engine implements. Exports use the C calling
// convention and so start without an Odin context, which is why each one sets up the
// default context first. The engine never runs Odin's entry point inside the module, so
// init starts the runtime.
package plugin

import "base:runtime"

import "engine:engine"
import wl "module:waylib"

log :: engine.log

ORBIT_CENTER :: wl.Vector2{250, 250}
ORBIT_RADIUS :: 100.0
MARKER_SIZE :: 16.0

Marker :: struct {
	position: wl.Vector2,
	angle:    f32,
}

marker: Marker

@(export)
init :: proc "c" () {
	// important preamble
	context = runtime.default_context() // odin things
	runtime._startup_runtime() // set up expression-inited globals (also transitively for imports)

	// begin user code
	marker = {}
	log(.INFO, "hello from plugin")
}

@(export)
update :: proc "c" (delta_time: f32) {
	// important preamble
	context = runtime.default_context() // odin things

	// begin user code
	marker.angle += delta_time
	marker.position = ORBIT_CENTER + wl.Vector2Rotate({ORBIT_RADIUS, 0}, marker.angle)
}

@(export)
draw :: proc "c" () {
	// important preamble
	context = runtime.default_context() // odin things

	// begin user code
	engine.DrawRectangleV(marker.position - MARKER_SIZE / 2, {MARKER_SIZE, MARKER_SIZE}, wl.YELLOW)
}
