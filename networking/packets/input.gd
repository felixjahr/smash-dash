class_name PlayerInput
extends Node

var tick: int

var direction := 0.0
var jumping := false
var current_weapon := 0
var attacking := false
var weapon_aim_directions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]


func to_dict() -> Dictionary:
	return {
		"tick" : tick,
		"direction" : direction,
		"jumping" : jumping,
		"current_weapon" : current_weapon,
		"attacking" : attacking,
		"weapon_aim_directions" : weapon_aim_directions,
	}


static func from_dict(data: Dictionary) -> PlayerInput:
	var input := PlayerInput.new()
	input.tick = data["tick"]
	input.direction = data["direction"]
	input.jumping = data["jumping"]
	input.current_weapon = data["current_weapon"]
	input.attacking = data["attacking"]
	input.weapon_aim_directions = data["weapon_aim_directions"]
	return input
