package heimdall_player

import "../input"
import rl "vendor:raylib"

Player :: struct {
	transform:    rl.Transform,
	velocity:     rl.Transform,
	acceleration: rl.Transform,
	// position:  rl.Vector2,
	// velocity:     rl.Vector2,
	speed:        f32, // pixels per second
	// size:         f32,
	color:        rl.Color,
}

player: Player

init :: proc() {
	player.transform.translation.xy = {10.0, 20.0}
	player.velocity.translation.xy = {0.0, 0.0}
	player.speed = 400.0
	player.transform.scale.xy = {10.0, 10.0}
	player.color = rl.RED
}

update :: proc() {
	player.velocity.translation.x = input.state.move.x * player.speed
	player.velocity.translation.y = input.state.move.y * player.speed
	player.transform.translation.x += player.velocity.translation.x * rl.GetFrameTime()
	player.transform.translation.y += player.velocity.translation.y * rl.GetFrameTime()
}

draw :: proc() {
	rl.DrawRectangleV(
		player.transform.translation.xy - player.transform.scale.xy / 2,
		player.transform.scale.xy,
		player.color,
	)

	if input.state.action_held {
		start_position: rl.Vector2 = player.transform.translation.xy
		end_position: rl.Vector2 = {250.0, 250.0}
		rl.DrawLineEx(start_position, end_position, thick = 2.0, color = rl.RED)
	}
}
