extends Node

signal input_received(pid: int, input: Dictionary)
signal peer_connected(pid: int)
signal peer_disconnected(pid: int)

const PORT := 9000


func start_match() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT, 8)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func send_init(pid: int, tick: int, pids: Array, map_id: String) -> void:
	rpc_id(pid, "receive_init", tick, pids, map_id)


func send_snapshot(tick: int, snapshot: Dictionary) -> void:
	rpc("receive_snapshot", tick, snapshot)


func send_shoot_event(tick: int, pid: int, weapon_number: int, shoot: Dictionary) -> void:
	rpc("receive_shoot_event", tick, pid, weapon_number, shoot)


func send_melee_event(tick: int, pid: int):
	rpc("receive_melee_event", tick, pid)


func send_ability_event(tick: int, pid: int):
	rpc("receive_ability_event", tick, pid)


func send_hit_event(tick: int, pid: int):
	rpc("receive_hit_event", tick, pid)


func send_connect_peer_event(pid: int) -> void:
	rpc("receive_connect_peer_event", pid)


func send_diconnect_peer_event(pid: int) -> void:
	rpc("receive_disconnect_peer_event", pid)


@rpc("any_peer", "unreliable")
func receive_input(input: Dictionary) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("input_received", pid, input)


func _on_peer_connected(pid: int) -> void:
	emit_signal("peer_connected", pid)


func _on_peer_disconnected(pid: int) -> void:
	emit_signal("peer_disconnected", pid)








@rpc("authority", "reliable")
func receive_init(tick: int, pids: Array, map_id: String) -> void:
	pass


@rpc("authority", "unreliable")
func receive_snapshot(tick: int, snapshot: Dictionary) -> void:
	pass


@rpc("authority", "reliable")
func receive_shoot_event(tick: int, pid: int, weapon_number: int, shoot: Dictionary) -> void:
	pass


@rpc("authority", "reliable")
func receive_melee_event(tick: int, pid: int):
	pass


@rpc("authority", "reliable")
func receive_ability_event(tick: int, pid: int):
	pass


@rpc("authority", "reliable")
func receive_hit_event(tick: int, pid: int):
	pass


@rpc("authority", "reliable")
func receive_connect_peer_event(pid: int) -> void:
	pass


@rpc("authority", "reliable")
func receive_disconnect_peer_event(pid: int) -> void:
	pass
