class_name Init
extends RefCounted

var tick: int

var map_id: String


func to_dict() -> Dictionary:
	return {
		"tick" : tick,
		"map_id" : map_id
	}


static func from_dict(data: Dictionary) -> Init:
	var init := Init.new()
	init.tick = data["tick"]
	init.map_id = data["map_id"]
	return init
