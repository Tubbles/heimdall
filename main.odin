package odin_game

import "core:fmt"

import rl "vendor:raylib"

init_window :: proc() {
	rl.InitWindow(500, 500, "Odin game")
	rl.SetExitKey(.KEY_NULL)
	rl.SetTraceLogLevel(.DEBUG)
}

init_systems :: proc() {
	input_load_keybindings()
	player_init()
}

update :: proc() {
	input_update()
	player_update()
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLUE)
	player_draw()
	rl.EndDrawing()
}

exit :: proc() {
	input_save_keybindings()
}

main :: proc() {
	init_window()
	init_systems()
	debug("hello world")

	for !rl.WindowShouldClose() {
		update()
		draw()

		if input.quit {
			rl.CloseWindow()
		}

		if input.reload {
			init_systems()
		}

		if input.toggle_console {
			console = !console
			debug("console toggled: {:v}", console)
		}
	}

	exit()
}
