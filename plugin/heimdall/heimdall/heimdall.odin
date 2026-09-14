package engine

import wl "module:waylib"

foreign import host "host"

@(default_calling_convention = "c")
foreign host {
	// Logs through the engine's logger, prefixed as a plugin message.
	log :: proc(level: wl.TraceLogLevel, message: string) ---
	DrawRectangleV :: proc(position: wl.Vector2, size: wl.Vector2, color: wl.Color) ---
	set_background_color :: proc(color: wl.Color) ---
}
