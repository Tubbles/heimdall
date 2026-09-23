package heimdall_cmd_render

import "../../console"
import "../../render"
import "../../flags_helpers"

Args :: struct {}

cmd := console.Command {
	name       = "render",
	short_help = "view current render settings",
	run        = run,
}

init :: proc() {
	cmd.help = flags_helpers.usage_text(Args, cmd.name)
	console.register_command(cmd)
}

run :: proc(args: []string) {
	if len(args) == 0 {
		console.printfln("{:v}", render.settings)
	} else {
		parsed_args: Args
		flags_helpers.parse(&parsed_args, args, cmd.help) // will just print help messages
	}

}
