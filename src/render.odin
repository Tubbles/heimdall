package heimdall

import "core:c"
import "core:strconv"
import rl "vendor:raylib"

Render_Settings :: struct {
	target_fps: int,
	vsync:      bool,
	fullscreen: bool,
}

settings := Render_Settings {
	target_fps = 120,
	vsync      = true,
	fullscreen = true,
}

target: rl.RenderTexture2D

source_rect, dest_rect: rl.Rectangle

render_cmd := Console_Command{name = "render", run = render_proc_cmd}
fps_cmd := Console_Command{name = "fps", run = render_set_target_fps_cmd}
fullscreen_cmd := Console_Command{name = "fullscreen", run = render_set_fullscreen_cmd}
vsync_cmd := Console_Command{name = "vsync", run = render_set_vsync_cmd}

on_change :: proc(user_data: rawptr) {
	render_update_all()
}

render_register_config :: proc() {
	config_register_section("render", &settings, on_change = on_change)
}

render_init :: proc() {
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE})
	rl.InitWindow(1280, 720, "Heimdall")
	render_update_all()

	rl.HideCursor()

	monitor := rl.GetCurrentMonitor()
	monitor_width := int(rl.GetMonitorWidth(monitor))
	monitor_height := int(rl.GetMonitorHeight(monitor))
	pixel_size: f32 = 2
	game_width := f32(monitor_width) / pixel_size
	game_height := f32(monitor_height) / pixel_size
	set_rectangles(monitor_width, monitor_height, int(game_width), int(game_height), &source_rect, &dest_rect)
	target = rl.LoadRenderTexture(c.int(source_rect.width), -c.int(source_rect.height))

	console_register_command(render_cmd)
	console_register_command(fps_cmd)
	console_register_command(fullscreen_cmd)
	console_register_command(vsync_cmd)
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

set_rectangles :: proc(
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
	settings.target_fps = fps
	render_update_target_fps()
	config_save(&heimdall_config_file)
}

render_update_target_fps :: proc() {
	rl.SetTargetFPS(i32(settings.target_fps))
}

render_set_vsync :: proc(vsync: bool) {
	settings.vsync = vsync
	render_update_vsync()
	config_save(&heimdall_config_file)
}

render_update_vsync :: proc() {
	if settings.vsync {
		rl.SetWindowState({.VSYNC_HINT})
	} else {
		rl.ClearWindowState({.VSYNC_HINT})
	}
}

render_set_fullscreen :: proc(fullscreen: bool) {
	settings.fullscreen = fullscreen
	render_update_fullscreen()
	config_save(&heimdall_config_file)
}

render_update_fullscreen :: proc() {
	if settings.fullscreen {
		rl.SetWindowState({.FULLSCREEN_MODE})
	} else {
		rl.ClearWindowState({.FULLSCREEN_MODE})
	}
}

render_update_all :: proc() {
	render_update_fullscreen()
	render_update_target_fps()
	render_update_vsync()
}

render_proc_cmd :: proc(args: []string) {
	if len(args) > 0 {
		console_printfln("Usage: %s", render_cmd.name)
		return
	}

	console_printfln("%s: {:v}", render_cmd.name, settings)
}

render_set_target_fps_cmd :: proc(args: []string) {
	if len(args) > 1 {
		console_printfln("Usage: %s [target-fps]", fps_cmd.name)
		return
	}

	if len(args) == 1 {
		target_fps, ok := strconv.parse_int(args[0])
		if !ok || target_fps < 0 {
			console_printfln("Invalid fps value '{}', expected a non-negative integer", args[0])
			return
		}
		render_set_target_fps(target_fps)
	} else {
		console_printfln("%s: {:v}", fps_cmd.name, settings.target_fps)
	}
}

render_set_vsync_cmd :: proc(args: []string) {
	if len(args) > 1 {
		console_printfln("Usage: %s [on|off]", fps_cmd.name)
		return
	}

	if len(args) == 1 {
		switch args[0] {
		case "on", "true", "1":
			render_set_vsync(true)
		case "off", "false", "0":
			render_set_vsync(false)
		case:
			console_printfln("Unknown vsync value '{}', expected on or off", args[0])
		}
	} else {
		console_printfln("%s: {:v}", fps_cmd.name, settings.vsync)
	}
}

render_set_fullscreen_cmd :: proc(args: []string) {
	if len(args) > 1 {
		console_printfln("Usage: %s [on|off]", fullscreen_cmd.name)
		return
	}

	if len(args) == 1 {
		switch args[0] {
		case "on", "true", "1":
			render_set_fullscreen(true)
		case "off", "false", "0":
			render_set_fullscreen(false)
		case:
			console_printfln("Unknown fullscreen value '{}', expected on or off", args[0])
		}
	} else {
		console_printfln("%s: {:v}", fullscreen_cmd.name, settings.fullscreen)
	}
}
