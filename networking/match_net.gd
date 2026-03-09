extends Node

signal input_received(pid: int, input: PlayerInput)
signal peer_connected(pid: int)
signal peer_disconnected(pid: int)

const PORT := 9000


func start_match() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(PORT, 8)
	multiplayer.multiplayer_peer = peer
	multiplayer.connect("peer_connected", _on_net_peer_connected)
	multiplayer.connect("peer_disconnected", _on_net_peer_disconnected)


func send_snapshot(snapshot: Snapshot) -> void:
	rpc("receive_snapshot", snapshot.to_dict())


func send_init(pid: int, init: Init) -> void:
	rpc_id(pid, "receive_init", init.to_dict())


@rpc("any_peer", "unreliable")
func receive_input(input: Dictionary) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("input_received", pid, PlayerInput.from_dict(input))


func _on_net_peer_connected(pid: int) -> void:
	emit_signal("peer_connected", pid)


func _on_net_peer_disconnected(pid: int) -> void:
	emit_signal("peer_disconnected", pid)






@rpc("authority", "unreliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	pass


@rpc("authority", "reliable")
func receive_init(init: Dictionary) -> void:
	pass
