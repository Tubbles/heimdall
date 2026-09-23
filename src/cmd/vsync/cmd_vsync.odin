package heimdall_cmd_vsync

import "../../console"
import "../../flags_helpers"
import "../../render"

Args :: struct {
	state: flags_helpers.Toggle `args:"pos=0" usage:"turn vsync 'on' or 'off'"`,
}

cmd := console.Command {
	name       = "vsync",
	short_help = "set or view the vsync setting",
	run        = run,
}

init :: proc() {
	cmd.help = flags_helpers.usage_text(Args, cmd.name)
	console.register_command(cmd)
}

run :: proc(args: []string) {
	if len(args) == 0 {
		console.printfln("{:v}", render.settings.vsync)
	} else {
		parsed_args: Args
		if flags_helpers.parse(&parsed_args, args, cmd.help) {
			render.set_vsync(bool(parsed_args.state))
		}
	}
}
