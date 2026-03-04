extends Node

signal match_started
signal snapshot_received(tick: int, snapshot: Dictionary)
signal peer_connected(pid: int)

#const IP_ADDRESS := "127.0.0.1"
const IP_ADDRESS := "34.185.168.1"
const PORT := 9000


func start_match() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer
	await multiplayer.connected_to_server
	emit_signal("match_started")


func send_input(input: Dictionary) -> void:
	var packed_input := Protocol.pack_input(input)
	rpc_id(1, "receive_input", packed_input)


@rpc("authority", "unreliable")
func receive_snapshot(tick: int, snapshot: Dictionary) -> void:
	emit_signal("snapshot_received", tick, snapshot)


@rpc("authority", "reliable")
func connect_peer(pid: int) -> void:
	emit_signal("peer_connected", pid)


@rpc("any_peer", "unreliable")
func receive_input(packed_input: int) -> void:
	pass
