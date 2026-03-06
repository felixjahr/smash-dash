extends Node

signal init_received(tick: int, pids: Array, map_id: String)
signal snapshot_received(tick: int, snapshot: Dictionary)
signal shoot_event_received(tick: int, pid: int, weapon_number: int, shoot: Dictionary)
signal melee_event_received(tick: int, pid: int)
signal ability_event_received(tick: int, pid: int)
signal hit_event_received(tick: int, pid: int)
signal connect_peer_event_received(pid: int)
signal diconnect_peer_event_received(pid: int)

const IP_ADDRESS := "127.0.0.1"
#const IP_ADDRESS := "34.185.168.1"
const PORT := 9000


func start_match() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer


func send_input(input: Dictionary) -> void:
	rpc_id(1, "receive_input", input)


@rpc("authority", "reliable")
func receive_init(tick: int, pids: Array, map_id: String) -> void:
	emit_signal("init_received", tick, pids, map_id)


@rpc("authority", "unreliable")
func receive_snapshot(tick: int, snapshot: Dictionary) -> void:
	emit_signal("snapshot_received", tick, snapshot)


@rpc("authority", "reliable")
func receive_shoot_event(tick: int, pid: int, weapon_number: int, shoot: Dictionary) -> void:
	emit_signal("shoot_event_received", tick, pid, weapon_number, shoot)


@rpc("authority", "reliable")
func receive_melee_event(tick: int, pid: int):
	emit_signal("melee_event_received", tick, pid)


@rpc("authority", "reliable")
func receive_ability_event(tick: int, pid: int):
	emit_signal("ability_event_received", tick, pid)


@rpc("authority", "reliable")
func receive_hit_event(tick: int, pid: int):
	emit_signal("hit_event_received", tick, pid)


@rpc("authority", "reliable")
func receive_connect_peer_event(pid: int) -> void:
	emit_signal("connect_peer_event_received", pid)


@rpc("authority", "reliable")
func receive_disconnect_peer_event(pid: int) -> void:
	emit_signal("diconnect_peer_event_received", pid)







@rpc("any_peer", "unreliable")
func receive_input(input: int) -> void:
	pass
