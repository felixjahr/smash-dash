extends Node

const MAPS = {
	"forest" : preload("res://maps/forest/forest.tscn"),
}

const Player := preload("res://player/player.tscn")

var players := {}

var overlay: Control

@onready var net := $"../Net"


func _ready() -> void:
	set_physics_process(false)


func start_match() -> void:
	net.start_match()


func _physics_process(delta: float) -> void:
	# Send input for server	
	var input := {
		"direction" : Input.get_axis("move_left", "move_right"),
		"jump_pressed" : Input.is_action_pressed("jump"),
		"aim_direction_1" : overlay.aim_joystick_1.output,
		"aim_direction_2" : overlay.aim_joystick_2.output,
	}
	net.send_input(input)


func _on_net_init_received(tick: int, pids: Array, map_id: String) -> void:
	var new_map = MAPS[map_id].instantiate()
	add_child(new_map)
	for pid in pids:
		var new_player = Player.instantiate()
		new_player.name = str(pid)
		add_child(new_player)
		players[pid] = new_player
	var new_player = Player.instantiate()
	new_player.name = str(multiplayer.get_unique_id())
	add_child(new_player)
	players[multiplayer.get_unique_id()] = new_player
	new_player.camera = get_child(0).camera
	set_physics_process(true)


func _on_net_snapshot_received(tick: int, snapshot: Dictionary) -> void:
	# Apply snapshot on client
	for pid in snapshot.keys():
		if not players.has(pid):
			continue
		players[pid].animate_snapshot(snapshot[pid])


func _on_net_shoot_event_received(tick: int, pid: int, weapon_number: int, shoot: Dictionary) -> void:
	players[pid].animate_shoot_event(weapon_number, shoot)


func _on_net_melee_event_received(tick: int, pid: int) -> void:
	players[pid].animate_melee_event()


func _on_net_ability_event_received(tick: int, pid: int) -> void:
	players[pid].animate_ability_event()


func _on_net_hit_event_received(tick: int, pid: int) -> void:
	players[pid].animate_hit_event()


func _on_net_connect_peer_event_received(pid: int) -> void:
	if pid == multiplayer.get_unique_id():
		return
	var new_player := Player.instantiate()
	new_player.name = str(pid)
	add_child(new_player)
	players[pid] = new_player


func _on_net_diconnect_peer_event_received(pid: int) -> void:
	players[pid].queue_free()
	players.erase(pid)
