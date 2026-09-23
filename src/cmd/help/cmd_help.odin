package heimdall_cmd_help

import "../../console"
import "../../flags_helpers"

Args :: struct {
	cmd: string `args:"pos=0" usage:"command to view detailed help about"`,
}

cmd := console.Command {
	name       = "help",
	short_help = "show detailed help about a command",
	run        = run,
}

init :: proc() {
	cmd.help = flags_helpers.usage_text(Args, cmd.name)
	console.register_command(cmd)
}

run :: proc(args: []string) {
	if len(args) == 0 {
		for name, cmd in console.registered_commands {
			console.printfln("{} - {}", name, cmd.short_help)
		}
	} else {
		parsed_args: Args
		if flags_helpers.parse(&parsed_args, args, cmd.help) {
			cmd, found := console.registered_commands[parsed_args.cmd]
			if !found {
				console.printfln("Unknown command '{}'", parsed_args.cmd)
				return
			}
			console.printfln("{} - {}", cmd.name, cmd.short_help)
			if cmd.help != "" {
				console.printfln("{}", cmd.help)
			}
		}
	}
}
