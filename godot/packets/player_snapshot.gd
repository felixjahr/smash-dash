class_name PlayerSnapshot
extends RefCounted

var player_id: String

var position: Vector2
var velocity: Vector2
var health: int
var hearts: int
var facing: int
var is_on_floor: bool
var current_weapon: int
var attacking: bool
var armour_id: String
var weapon_ids: Array[String]
var weapon_aim_directions: Array[Vector2]
var weapon_ammunitions: Array[int]
var last_hit: int
