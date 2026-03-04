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


func send_snapshot(tick: int, snapshot: Dictionary) -> void:
	rpc("receive_snapshot", tick, snapshot)


@rpc("any_peer", "unreliable")
func receive_input(packed_input: int) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("input_received", pid, Protocol.unpack_input(packed_input))


func _on_peer_connected(pid: int) -> void:
	for existing_pid in multiplayer.get_peers():
		if existing_pid == pid:
			continue
		rpc_id(pid, "connect_peer", existing_pid)
	rpc("connect_peer", pid)
	emit_signal("peer_connected", pid)


func _on_peer_disconnected(pid: int) -> void:
	rpc("disconnect_peer", pid)
	emit_signal("peer_disconnected", pid)


@rpc("authority", "unreliable")
func receive_snapshot(tick: int, snapshot: Dictionary) -> void:
	pass


@rpc("authority", "reliable")
func connect_peer(pid: int) -> void:
	pass


@rpc("authority", "reliable")
func disconnect_peer(pid: int) -> void:
	pass
