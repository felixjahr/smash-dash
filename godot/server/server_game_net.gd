extends Node

signal input_received(player_id: String, input: PlayerInput)
signal game_token_received(pid: int, game_token: String)
signal game_request_received(player_id: String, game_request: GameRequest)

@onready var controller := $"../.."


func create_server(port: int) -> void:
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, 8)
	multiplayer.multiplayer_peer = peer


func send_snapshot(snapshot: Snapshot) -> void:
	rpc("receive_snapshot", snapshot.to_dict())


@rpc("authority", "unreliable")
func receive_snapshot(snapshot: Dictionary) -> void:
	pass


func send_init(player_id: String, game_id: String, map_id: String) -> void:
	var pid: int = controller.pid_by_player_id[player_id]
	rpc_id(pid, "receive_init",game_id, map_id)


@rpc("authority", "reliable")
func receive_init(game_id: String, map_id: String) -> void:
	pass


func send_state_sync(player_id: String, state_sync: StateSync) -> void:
	var pid: int = controller.pid_by_player_id[player_id]
	rpc_id(pid, "receive_state_sync", state_sync.to_dict())


@rpc("authority", "reliable")
func receive_state_sync(state_sync: Dictionary) -> void:
	pass


@rpc("any_peer", "unreliable")
func receive_input(input: Dictionary) -> void:
	var player_id: String = controller.player_id_by_pid[multiplayer.get_remote_sender_id()]
	emit_signal("input_received", player_id, PlayerInput.from_dict(input))


@rpc("any_peer", "reliable")
func receive_game_token(game_token: String) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("game_token_received", pid, game_token)


@rpc("any_peer", "unreliable")
func receive_game_request(game_request: Dictionary) -> void:
	var player_id: String = controller.player_id_by_pid[multiplayer.get_remote_sender_id()]
	emit_signal("game_request_received", player_id, GameRequest.from_dict(game_request))
