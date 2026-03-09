extends Node

signal snapshot_received(snapshot: Snapshot)
signal init_received(init: Init)

#const IP_ADDRESS := "127.0.0.1"
const IP_ADDRESS := "34.185.168.1"
const PORT := 9000


func start_match() -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(IP_ADDRESS, PORT)
	multiplayer.multiplayer_peer = peer


func send_input(input: PlayerInput) -> void:
	rpc_id(1, "receive_input", input.to_dict())


@rpc("authority", "reliable")
func receive_init(init: Dictionary) -> void:
	emit_signal("init_received", Init.from_dict(init))


@rpc("authority", "unreliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	emit_signal("snapshot_received", Snapshot.from_dict(snapshot))


@rpc("any_peer", "unreliable")
func receive_input(input: PlayerInput) -> void:
	pass
