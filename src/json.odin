package heimdall

import "core:encoding/json"
import "core:io"
import "core:strconv"

// Registry handed to core:encoding/json, which accepts exactly one per process.
// Other modules that need custom marshalers register into it after config_init.
@(private = "file")
user_marshalers: map[typeid]json.User_Marshaler

json_register_float_marshalers :: proc() {
	if json._user_marshalers == nil do json.set_user_marshalers(&user_marshalers)
	// already registered on re-init (e.g. reload); the result is the same marshaler
	json.register_user_marshaler(typeid_of(f32), marshal_float_shortest)
	json.register_user_marshaler(typeid_of(f64), marshal_float_shortest)
}

json_unregister_float_marshalers :: proc() {
	if json._user_marshalers == &user_marshalers {
		delete(user_marshalers)
		user_marshalers = {}
	}
}

// Writes the shortest text that round-trips at the value's own precision
// (120, 0.1, 0.33333334). The io default is fixed notation with 8 decimals for
// f32 and 16 for f64, e.g. `120.0000000000000000`.
@(private = "file")
marshal_float_shortest :: proc(w: io.Writer, v: any, opt: ^json.Marshal_Options) -> json.Marshal_Error {
	buffer: [386]byte // sized like io.write_f64: 'f' notation spells out every integer digit
	text: string
	switch f in v {
	case f32:
		text = strconv.write_float(buffer[:], f64(f), 'f', -1, 32)
	case f64:
		text = strconv.write_float(buffer[:], f, 'f', -1, 64)
	case:
		return .Unsupported_Type
	}
	if text[0] == '+' do text = text[1:] // strconv always writes a sign
	io.write_string(w, text) or_return
	return nil
}
