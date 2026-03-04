extends Node

const DEFAULT_INPUT = {
	"input_dir" : 0,
	"jump_pressed" : false,
}

const Player := preload("res://player/player.tscn")
const Map := preload("res://maps/forest/forest.tscn")

var tick: int = 0

var players := {}
var inputs := {}

@onready var net := $"../Net"


func start_match() -> void:
	var new_map = Map.instantiate()
	add_child(new_map)


func game_tick(delta: float) -> void:
	tick += 1
	
	# Simulate input on server
	for pid in players.keys():
		var input: Dictionary = inputs.get(pid, DEFAULT_INPUT)
		players[pid].simulate(input["input_dir"], input["jump_pressed"], delta)
	
	if tick % 3 == 0:
		_send_snapshot()


func _send_snapshot() -> void:
	# Send snapshot for client
	var snapshot := {}
	for pid in players.keys():
		var player: CharacterBody2D = players[pid]
		snapshot[pid] = {
			"px": player.global_position.x,
			"py": player.global_position.y,
			"vx": player.velocity.x,
			"vy": player.velocity.y,
			"j" : player.jumping,
		}
	net.send_snapshot(tick, snapshot)


func _on_net_input_received(pid: int, input: Dictionary) -> void:
	inputs[pid] = input


func _on_net_peer_connected(pid: int) -> void:
	var new_player := Player.instantiate()
	new_player.name = str(pid)
	add_child(new_player)
	players[pid] = new_player
	inputs[pid] = DEFAULT_INPUT
