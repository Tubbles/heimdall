package heimdall_cmd_fullscreen

import "../console"
import "../flags_helpers"
import "../render"
import "core:flags"

State :: enum {
	on,
	off,
}

Args :: struct {
	state: State `args:"pos=0" usage:"turn fullscreen 'on' or 'off'"`,
}

cmd := console.Command {
	name       = "fullscreen",
	short_help = "set or view the fullscreen setting",
	run        = run,
}

init :: proc() {
	cmd.help = flags_helpers.usage_text(Args, cmd.name)
	console.register_command(cmd)
}

run :: proc(args: []string) {
	parsed_args: Args
	if parse_result := flags.parse(&parsed_args, args); parse_result == nil {
		if len(args) == 0 {
			console.printfln("{:v}", render.settings.fullscreen)
		} else {
			render.set_fullscreen(parsed_args.state == .on)
		}
	} else {
		if parse_error, ok := parse_result.(flags.Parse_Error); ok {
			console.printfln("%s", parse_error.message)
		}
		console.printfln("%s", cmd.help)
	}
}
