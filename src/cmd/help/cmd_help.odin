package heimdall_cmd_help

import "../console"
import "../flags_helpers"
import "core:flags"

Args :: struct {
	cmd: string `args:"pos=0" usage:"command to view detailed help about"`,
}

cmd := console.Command {
	name       = "help",
	short_help = "show detailed help about a command, or print an overview of all commands",
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
			for name, cmd in console.registered_commands {
				console.printfln("{} - {}", name, cmd.short_help)
			}
		} else {
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
	} else {
		if parse_error, ok := parse_result.(flags.Parse_Error); ok {
			console.printfln("%s", parse_error.message)
		}
		console.printfln("%s", cmd.help)
	}
}
