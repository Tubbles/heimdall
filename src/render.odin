package heimdall

import "./log"
import "core:c"
import "core:encoding/json"
import "core:os"
import "core:slice"
import rl "vendor:raylib"

RENDER_JSON_SPEC :: json.Specification.SJSON
RENDER_SETTINGS_FILENAME :: "render.sjson"

Render_Settings :: struct {
	target_fps: int,
}

render_settings := Render_Settings {
	target_fps = 120,
}

target: rl.RenderTexture2D

source_rect, dest_rect: rl.Rectangle

render_init :: proc() {
	render_load_settings()
	// rl.SetConfigFlags({.VSYNC_HINT, .BORDERLESS_WINDOWED_MODE, .FULLSCREEN_MODE, .WINDOW_UNDECORATED})
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE, .FULLSCREEN_MODE, .WINDOW_UNDECORATED})
	rl.InitWindow(1920, 1080, "Heimdall")
	rl.SetTargetFPS(i32(render_settings.target_fps))

	rl.HideCursor()

	monitor := rl.GetCurrentMonitor()
	monitor_width := int(rl.GetMonitorWidth(monitor))
	monitor_height := int(rl.GetMonitorHeight(monitor))
	pixel_size: f32 = 2
	game_width := f32(monitor_width) / pixel_size
	game_height := f32(monitor_height) / pixel_size
	render_set_rectangles(monitor_width, monitor_height, int(game_width), int(game_height), &source_rect, &dest_rect)
	target = rl.LoadRenderTexture(c.int(source_rect.width), -c.int(source_rect.height))
}

render_exit :: proc() {
	render_save_settings()
}

// render_update :: proc() {
// 	//
// }

render_load_settings :: proc() {
	config_load(RENDER_SETTINGS_FILENAME, &render_settings)
}

render_save_settings :: proc() {
	config_save(RENDER_SETTINGS_FILENAME, render_settings)
}

render_begin :: proc() {
	rl.BeginTextureMode(target)
	rl.ClearBackground(background_color)
}

render_end :: proc() {
	rl.EndTextureMode()
	rl.BeginDrawing()
	rl.DrawTexturePro(target.texture, source_rect, dest_rect, rl.Vector2{0.0, 0.0}, 0.0, background_color)
	rl.DrawRectangleV(rl.GetMousePosition(), rl.Vector2{10.0, 10.0}, rl.DARKGREEN)
	rl.DrawFPS(0, 0)
	rl.EndDrawing()
}

render_set_rectangles :: proc(
	screen_width, screen_height, game_width, game_height: int,
	source_rect, dest_rect: ^rl.Rectangle,
) {
	source_rect^.x = 0.0
	source_rect^.y = f32(game_height)
	source_rect^.width = f32(game_width)
	source_rect^.height = f32(-game_height)

	ratio_x: int = (screen_width / game_width)
	ratio_y: int = (screen_height / game_height)
	resizeRatio: f32 = f32(((ratio_x < ratio_y) ? ratio_x : ratio_y))

	dest_rect^.x = f32(int(((f32(screen_width) - (f32(game_width) * resizeRatio)) * 0.5)))
	dest_rect^.y = f32(int(((f32(screen_height) - (f32(game_height) * resizeRatio)) * 0.5)))
	dest_rect^.width = f32(int((f32(game_width) * resizeRatio)))
	dest_rect^.height = f32(int((f32(game_height) * resizeRatio)))
}

render_set_target_fps :: proc(fps: int) {
	render_settings.target_fps = fps
	rl.SetTargetFPS(i32(render_settings.target_fps))
}
