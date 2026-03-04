class_name Protocol
extends Object


static func pack_input(input: Dictionary) -> int:
	var d: int = input["input_dir"] + 1
	var j := 1 if input["jump_pressed"] else 0
	return (d & 0b11) | (j << 2)


static func unpack_input(packed_input: int) -> Dictionary:
	var d := (packed_input & 0b11) - 1
	var j := ((packed_input >> 2) & 0b1) == 1
	return {"input_dir": d, "jump_pressed": j}
