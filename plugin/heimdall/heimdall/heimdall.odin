package engine

import wl "module:waylib"

foreign import heimdall "heimdall"

@(default_calling_convention = "c")
foreign heimdall {
	trace :: proc(message: string) ---
	debug :: proc(message: string) ---
	info :: proc(message: string) ---
	warning :: proc(message: string) ---
	error :: proc(message: string) ---
	fatal :: proc(message: string) ---
	DrawRectangleV :: proc(position: wl.Vector2, size: wl.Vector2, color: wl.Color) ---
	set_background_color :: proc(color: wl.Color) ---
}
