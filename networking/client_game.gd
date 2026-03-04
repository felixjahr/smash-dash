extends Node

const Player := preload("res://player/player.tscn")
const Map := preload("res://maps/forest/forest.tscn")

var players := {}

@onready var net := $"../Net"


func start_match() -> void:
	var new_map = Map.instantiate()
	add_child(new_map)


func game_tick(delta: float) -> void:
	# Send input for server
	var input = {
		"input_dir" : int(Input.get_axis("move_left", "move_right")),
		"jump_pressed" : Input.is_action_pressed("jump")
	}
	
	net.send_input(input)


func _on_net_snapshot_received(tick: int, snapshot: Dictionary) -> void:
	# Simulate snapshot on client
	for pid in snapshot.keys():
		if not players.has(pid):
			continue
		var s: Dictionary = snapshot[pid]
		
		var player: CharacterBody2D = players[pid]
		player.global_position = Vector2(s["px"], s["py"])
		player.velocity = Vector2(s["vx"], s["vy"])
		player.animate(s["j"])
		get_node("Forest/Camera2D").global_position = player.global_position


func _on_net_peer_connected(pid: int) -> void:
	if players.has(pid):
		return
	var new_player := Player.instantiate()
	new_player.name = str(pid)
	add_child(new_player)
	players[pid] = new_player
