package heimdall_cmd_fps

import "../../console"
import "../../flags_helpers"
import "../../render"

Args :: struct {
	target_fps: int `args:"pos=0" usage:"the target fps, set to negative for unlimited fps"`,
}

cmd := console.Command {
	name       = "fps",
	short_help = "set or view the target fps setting",
	run        = run,
}

init :: proc() {
	cmd.help = flags_helpers.usage_text(Args, cmd.name)
	console.register_command(cmd)
}

run :: proc(args: []string) {
	if len(args) == 0 {
		console.printfln("{:v}", render.settings.target_fps)
	} else {
		parsed_args: Args
		if flags_helpers.parse(&parsed_args, args, cmd.help) {
			render.set_target_fps(parsed_args.target_fps)
		}
	}
}
