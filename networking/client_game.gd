extends Node

const PlayerScene := preload("res://player/player.tscn")
const Map := preload("res://maps/forest/forest.tscn")

var players := {}

@onready var net := $"../Net"


func _ready() -> void:
	set_physics_process(false)


func _physics_process(delta: float) -> void:
	# Send input for server	
	net.send_input(Player.get_input())


func _on_net_snapshot_received(tick: int, snapshot: Dictionary) -> void:
	# Apply snapshot on client
	for pid in snapshot.keys():
		if not players.has(pid):
			continue
		var player: CharacterBody2D = players[pid]
		var own: bool = pid == multiplayer.get_unique_id()
		player.apply_snapshot(snapshot[pid], own)


func _on_net_init_received(tick: int) -> void:
	var new_map = Map.instantiate()
	add_child(new_map)
	set_physics_process(true)


func _on_net_peer_connected(pid: int) -> void:
	var new_player := PlayerScene.instantiate()
	new_player.name = str(pid)
	add_child(new_player)
	players[pid] = new_player


func _on_net_peer_disconnected(pid: int) -> void:
	players[pid].queue_free()
	players.erase(pid)
