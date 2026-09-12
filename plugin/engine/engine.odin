package engine

foreign import host "host"

@(default_calling_convention = "c")
foreign host {
	// Logs through the engine's logger, prefixed as a plugin message.
	TraceLog :: proc(level: TraceLogLevel, message: string) ---
	DrawRectangleV :: proc(position: Vector2, size: Vector2, color: Color) ---
}
