class_name PlayerSnapshot
extends RefCounted

var pid: int

var position: Vector2
var velocity: Vector2
var health: int
var facing: int
var is_on_floor: bool
var current_weapon: int
var attacking: bool
var armour_id: String
var weapon_ids: Array[String]
var weapon_aim_directions: Array[Vector2]
var weapon_ammunitions: Array[int]
var last_hit: int


func to_dict() -> Dictionary:
	return {
		"pid" : pid,
		"position" : position,
		"velocity" : velocity,
		"health" : health,
		"facing" : facing,
		"is_on_floor" : is_on_floor,
		"current_weapon" : current_weapon,
		"attacking" : attacking,
		"armour_id" : armour_id,
		"weapon_ids" : weapon_ids,
		"weapon_aim_directions" : weapon_aim_directions,
		"weapon_ammunitions" : weapon_ammunitions,
		"last_hit" : last_hit
	}


static func from_dict(data: Dictionary) -> PlayerSnapshot:
	var snapshot := PlayerSnapshot.new()
	snapshot.pid = data["pid"]
	snapshot.position = data["position"]
	snapshot.velocity = data["velocity"]
	snapshot.health = data["health"]
	snapshot.facing = data["facing"]
	snapshot.is_on_floor = data["is_on_floor"]
	snapshot.current_weapon = data["current_weapon"]
	snapshot.attacking = data["attacking"]
	snapshot.armour_id = data["armour_id"]
	snapshot.weapon_ids = data["weapon_ids"]
	snapshot.weapon_aim_directions = data["weapon_aim_directions"]
	snapshot.weapon_ammunitions = data["weapon_ammunitions"]
	snapshot.last_hit = data["last_hit"]
	return snapshot
