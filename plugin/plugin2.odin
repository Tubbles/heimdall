// Example game plugin, built to WebAssembly by build.sh and loaded by plugin_host.odin.
//
// The engine calls the exported procedures and the plugin talks back through
// module:waylib, a raylib-shaped API the engine implements. Exports use the C calling
// convention and so start without an Odin context, which is why each one sets up the
// default context first. The engine never runs Odin's entry point inside the module, so
// init starts the runtime.
package plugin2

import "base:runtime"

import wl "module:waylib"
import "engine:engine"

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
	context = runtime.default_context()
	runtime._startup_runtime()
	marker = {}
	engine.log(.INFO, "hello from plugin")
}

@(export)
update :: proc "c" (delta_time: f32) {
	context = runtime.default_context()
	marker.angle += delta_time
	marker.position = ORBIT_CENTER + wl.Vector2Rotate({ORBIT_RADIUS, 0}, marker.angle)
}

@(export)
draw :: proc "c" () {
	context = runtime.default_context()
	engine.DrawRectangleV(marker.position - MARKER_SIZE / 2, {MARKER_SIZE, MARKER_SIZE}, wl.YELLOW)
}
