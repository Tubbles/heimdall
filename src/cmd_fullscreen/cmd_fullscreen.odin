package heimdall_cmd_fullscreen

import "../console"
import "../flags_helpers"
import "../render"
import "core:flags"
import "core:strings"

// The enum member names double as the words accepted on the command line
State :: enum {
	on,
	off,
}

Args :: struct {
	state: State `args:"pos=0,required" usage:"turn fullscreen on or off, omit to print the current state"`,
}

cmd := console.Command {
	name = "fullscreen",
	run  = run,
}

init :: proc() {
	// Both help texts come out of the args struct so the tags stay the only place the
	// argument is described. They are allocated once and live as long as the command table
	cmd.short_help = flags_helpers.field_usage(Args, "state")
	cmd.help = flags_helpers.usage_text(Args, cmd.name)
	console.register_command(cmd)
}

run :: proc(args: []string) {
	// The query form takes no arguments at all, which core:flags cannot express for a
	// required positional, so it is handled before the parser runs
	if len(args) == 0 {
		console.printfln("%s: {:v}", cmd.name, render.settings.fullscreen)
		return
	}

	parsed_args: Args
	if parse_result := flags.parse(&parsed_args, args); parse_result != nil {
		if parse_error, ok := parse_result.(flags.Parse_Error); ok {
			console.printfln("%s", parse_error.message)
		}
		// write_usage spans several lines, the scrollback holds one line per entry
		usage_lines := cmd.help
		for line in strings.split_lines_iterator(&usage_lines) {
			console.printfln("%s", line)
		}
		return
	}

	render.set_fullscreen(parsed_args.state == .on)
}
