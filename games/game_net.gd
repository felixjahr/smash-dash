extends Node

signal snapshot_received(snapshot: Snapshot)
signal init_received(init: Init)
signal game_event_received(game_event: GameEvent)

signal input_received(pid: int, input: PlayerInput)
signal game_request_received(pid: int, game_request: GameRequest)
signal peer_connected(pid: int)
signal peer_disconnected(pid: int)


func create_client(port: int, ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer


func close_client() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null


func create_server(port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, 8)
	multiplayer.multiplayer_peer = peer
	multiplayer.connect("peer_connected", _on_net_peer_connected)
	multiplayer.connect("peer_disconnected", _on_net_peer_disconnected)


func send_input(input: PlayerInput) -> void:
	rpc_id(1, "receive_input", input.to_dict())


@rpc("any_peer", "unreliable")
func receive_input(input: Dictionary) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("input_received", pid, PlayerInput.from_dict(input))


func send_game_request(game_request: GameRequest) -> void:
	rpc_id(1, "receive_game_request", game_request.to_dict())


@rpc("any_peer", "unreliable")
func receive_game_request(game_request: Dictionary) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("game_request_received", pid, GameRequest.from_dict(game_request))


func send_snapshot(snapshot: Snapshot) -> void:
	rpc("receive_snapshot", snapshot.to_dict())


@rpc("authority", "unreliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	emit_signal("snapshot_received", Snapshot.from_dict(snapshot))


func send_init(pid: int, init: Init) -> void:
	rpc_id(pid, "receive_init", init.to_dict())


@rpc("authority", "reliable")
func receive_init(init: Dictionary) -> void:
	emit_signal("init_received", Init.from_dict(init))


func send_game_event(pid: int, game_event: GameEvent) -> void:
	rpc_id(pid, "receive_game_event", game_event.to_dict())


@rpc("authority", "reliable")
func receive_game_event(game_event: Dictionary) -> void:
	emit_signal("game_event_received", GameEvent.from_dict(game_event))


func _on_net_peer_connected(pid: int) -> void:
	emit_signal("peer_connected", pid)


func _on_net_peer_disconnected(pid: int) -> void:
	emit_signal("peer_disconnected", pid)
