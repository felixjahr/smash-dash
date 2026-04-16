extends Node

signal room_code_received(code: String)
signal room_start_received(port: int, ip: String, game_id: String, map_id: String)

signal room_created(pid: int)
signal room_joined(pid: int, code: String)


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
	peer.create_server(port, 64)
	multiplayer.multiplayer_peer = peer


func send_create_room() -> void:
	rpc_id(1, "receive_create_room")


@rpc("any_peer", "reliable")
func receive_create_room() -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("room_created", pid)


func send_join_room(code: String) -> void:
	rpc_id(1, "receive_join_room", code)


@rpc("any_peer", "reliable")
func receive_join_room(code: String) -> void:
	var pid := multiplayer.get_remote_sender_id()
	emit_signal("room_joined", pid, code)


func send_room_code(pid: int, code: String) -> void:
	rpc_id(pid, "receive_room_code", code)


@rpc("authority", "reliable")
func receive_room_code(code: String) -> void:
	emit_signal("room_code_received", code)


func send_room_start(pid: int, port: int, ip: String) -> void:
	rpc_id(pid, "receive_room_start", port, ip)


@rpc("authority", "reliable")
func receive_room_start(port: int, ip: String) -> void:
	emit_signal("room_start_received", port, ip)
