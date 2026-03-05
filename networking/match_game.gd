extends Node

const PlayerScene := preload("res://player/player.tscn")
const Map := preload("res://maps/forest/forest.tscn")

var tick: int = 0

var players := {}
var inputs := {}

@onready var net := $"../Net"


func _ready() -> void:
	set_physics_process(false)


func start_match() -> void:
	var new_map = Map.instantiate()
	add_child(new_map)
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	tick += 1
	
	# Apply input on server
	for pid in players.keys():
		var input: Dictionary = inputs.get(pid, Player.DEFAULT_INPUT)
		players[pid].apply_input(input, delta)
	
	# Send snapshot for client
	if tick % 3 == 0:
		var snapshot := {}
		for pid in players.keys():
			var player: CharacterBody2D = players[pid]
			snapshot[pid] = player.get_snapshot()
		net.send_snapshot(tick, snapshot)


func _on_net_input_received(pid: int, input: Dictionary) -> void:
	inputs[pid] = input


func _on_net_peer_connected(pid: int) -> void:
	var new_player := PlayerScene.instantiate()
	new_player.name = str(pid)
	add_child(new_player)
	players[pid] = new_player
	inputs[pid] = Player.DEFAULT_INPUT
	net.send_init(tick)


func _on_net_peer_disconnected(pid: int) -> void:
	players[pid].queue_free()
	players.erase(pid)
