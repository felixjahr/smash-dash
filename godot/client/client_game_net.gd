extends Node

signal snapshot_received(snapshot: Snapshot)
signal init_received(game_id: String, map_id: String)
signal state_sync_received(state_sync: StateSync)


func create_client(port: int, ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer


func send_input(input: PlayerInput) -> void:
	rpc_id(1, "receive_input", input.to_dict())


func send_game_token(game_token: String) -> void:
	rpc_id(1, "receive_game_token", game_token)


func send_game_request(game_request: GameRequest) -> void:
	rpc_id(1, "receive_game_request", game_request.to_dict())


@rpc("authority", "unreliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	emit_signal("snapshot_received", Snapshot.from_dict(snapshot))


@rpc("authority", "reliable")
func receive_init(game_id: String, map_id: String) -> void:
	emit_signal("init_received", game_id, map_id)


@rpc("authority", "reliable")
func receive_state_sync(state_sync: Dictionary) -> void:
	emit_signal("state_sync_received", StateSync.from_dict(state_sync))


@rpc("any_peer", "unreliable")
func receive_input(input: Dictionary) -> void:
	pass


@rpc("any_peer", "reliable")
func receive_game_token(game_token: String) -> void:
	pass


@rpc("any_peer", "unreliable")
func receive_game_request(game_request: Dictionary) -> void:
	pass
