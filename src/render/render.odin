package heimdall_render

import "../config"
import "../console"
import "core:c"
import "core:strconv"
import rl "vendor:raylib"

Settings :: struct {
	target_fps: int,
	vsync:      bool,
	fullscreen: bool,
}

settings := Settings {
	target_fps = 120,
	vsync      = true,
	fullscreen = true,
}

target: rl.RenderTexture2D

source_rect, dest_rect: rl.Rectangle

background_color := rl.WHITE

cmd := console.Command {
	name = "render",
	run  = proc_cmd,
}

fps_cmd := console.Command {
	name = "fps",
	run  = set_target_fps_cmd,
}

vsync_cmd := console.Command {
	name = "vsync",
	run  = set_vsync_cmd,
}

on_change :: proc(user_data: rawptr) {
	update_all()
}

register_config :: proc() {
	config.register_section("render", &settings, on_change = on_change)
}

init :: proc() {
	rl.SetConfigFlags({.BORDERLESS_WINDOWED_MODE})
	rl.InitWindow(1280, 720, "Heimdall")
	update_all()

	rl.HideCursor()

	monitor := rl.GetCurrentMonitor()
	monitor_width := int(rl.GetMonitorWidth(monitor))
	monitor_height := int(rl.GetMonitorHeight(monitor))
	pixel_size: f32 = 2
	game_width := f32(monitor_width) / pixel_size
	game_height := f32(monitor_height) / pixel_size
	set_rectangles(monitor_width, monitor_height, int(game_width), int(game_height), &source_rect, &dest_rect)
	target = rl.LoadRenderTexture(c.int(source_rect.width), -c.int(source_rect.height))

	console.register_command(cmd)
	console.register_command(fps_cmd)
	console.register_command(vsync_cmd)
}

begin :: proc() {
	rl.BeginTextureMode(target)
	rl.ClearBackground(background_color)
}

end :: proc() {
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

set_target_fps :: proc(fps: int) {
	settings.target_fps = fps
	update_target_fps()
	config.save(&config.global_file)
}

update_target_fps :: proc() {
	rl.SetTargetFPS(i32(settings.target_fps))
}

set_vsync :: proc(vsync: bool) {
	settings.vsync = vsync
	update_vsync()
	config.save(&config.global_file)
}

update_vsync :: proc() {
	if settings.vsync {
		rl.SetWindowState({.VSYNC_HINT})
	} else {
		rl.ClearWindowState({.VSYNC_HINT})
	}
}

set_fullscreen :: proc(fullscreen: bool) {
	settings.fullscreen = fullscreen
	update_fullscreen()
	config.save(&config.global_file)
}

update_fullscreen :: proc() {
	if settings.fullscreen {
		rl.SetWindowState({.FULLSCREEN_MODE})
	} else {
		rl.ClearWindowState({.FULLSCREEN_MODE})
	}
}

update_all :: proc() {
	update_fullscreen()
	update_target_fps()
	update_vsync()
}

proc_cmd :: proc(args: []string) {
	if len(args) > 0 {
		console.printfln("Usage: %s", cmd.name)
		return
	}

	console.printfln("%s: {:v}", cmd.name, settings)
}

set_target_fps_cmd :: proc(args: []string) {
	if len(args) > 1 {
		console.printfln("Usage: %s [target-fps]", fps_cmd.name)
		return
	}

	if len(args) == 1 {
		target_fps, ok := strconv.parse_int(args[0])
		if !ok || target_fps < 0 {
			console.printfln("Invalid fps value '{}', expected a non-negative integer", args[0])
			return
		}
		set_target_fps(target_fps)
	} else {
		console.printfln("%s: {:v}", fps_cmd.name, settings.target_fps)
	}
}

set_vsync_cmd :: proc(args: []string) {
	if len(args) > 1 {
		console.printfln("Usage: %s [on|off]", fps_cmd.name)
		return
	}

	if len(args) == 1 {
		switch args[0] {
		case "on", "true", "1":
			set_vsync(true)
		case "off", "false", "0":
			set_vsync(false)
		case:
			console.printfln("Unknown vsync value '{}', expected on or off", args[0])
		}
	} else {
		console.printfln("%s: {:v}", fps_cmd.name, settings.vsync)
	}
}
