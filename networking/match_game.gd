extends Node

const DEFAULT_INPUT = {
	"direction" : 0,
	"jump_pressed" : false,
	"aim_direction_1" : Vector2.ZERO,
	"aim_direction_2" : Vector2.ZERO
}

const MAPS = {
	"forest" : preload("res://maps/forest/forest.tscn"),
	"mountains" : preload("res://maps/mountains/mountains.tscn"),
}

const Player := preload("res://player/player.tscn")

var tick: int = 0
var map_id: String = "mountains"

var players := {}
var inputs := {}

@onready var net := $"../Net"


func start_match() -> void:
	var new_map = MAPS[map_id].instantiate()
	add_child(new_map)
	net.start_match()


func _physics_process(delta: float) -> void:
	tick += 1
	
	# Apply input on server
	for pid in players.keys():
		var input: Dictionary = inputs.get(pid, DEFAULT_INPUT)
		players[pid].simulate_input(input, delta)
	
	# Send snapshot for client
	if tick % 3 == 0:
		var snapshot := {}
		for pid in players.keys():
			var player: CharacterBody2D = players[pid]
			snapshot[pid] = {
				"global_position" : player.global_position,
				"velocity" : player.velocity,
				"jumping" : player.jumping,
				"aim_direction_1" : player.aim_direction_1,
				"aim_direction_2" : player.aim_direction_2,
				"ammunition_1" : player.weapon_1.ammunition,
				"ammunition_2" : player.weapon_2.ammunition,
				"health" : player.health,
				"attacking" : player.attacking,
 			}
		net.send_snapshot(tick, snapshot)


func send_attack_event(pid: int, weapon_number: int, attack: Dictionary) -> void:
	net.send_attack_event(tick, pid, weapon_number, attack)


func send_despawn_bullet_event(bullet_id: int) -> void:
	net.send_despawn_bullet_event(tick, bullet_id)


func send_ability_event(pid: int) -> void:
	net.send_ability_event(tick, pid)


func send_hit_event(pid: int) -> void:
	net.send_hit_event(tick, pid)


func _on_net_input_received(pid: int, input: Dictionary) -> void:
	inputs[pid] = input


func _on_net_peer_connected(pid: int) -> void:
	net.send_init(pid, tick, players.keys(), map_id)
	var new_player := Player.instantiate()
	new_player.name = str(pid)
	add_child(new_player)
	players[pid] = new_player
	inputs[pid] = DEFAULT_INPUT
	net.send_connect_peer_event(pid)


func _on_net_peer_disconnected(pid: int) -> void:
	players[pid].queue_free()
	players.erase(pid)
	net.send_diconnect_peer_event(pid)
