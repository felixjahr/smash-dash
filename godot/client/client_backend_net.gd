extends Node

signal room_code_received(code: String)
signal room_start_received(port: int, ip: String, game_token: String, player_names: Dictionary)
signal room_failed_received

const HTTP_BASE := "http://35.246.204.169:8000"

const WS_URL := "ws://35.246.204.169:8000/ws"
const WS_CONNECT_TIMEOUT := 8.0
const WS_AUTH_TIMEOUT := 8.0
var socket := WebSocketPeer.new()
var socket_authed := false

@onready var auth_net := $"../AuthNet"


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	socket.poll()
	if socket_authed and socket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		socket_authed = false
		set_process(false)
		emit_signal("room_failed_received")
		return
	while socket.get_available_packet_count() > 0:
		var msg = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		if not (msg is Dictionary):
			continue
		var event := str(msg.get("event", ""))
		var data: Dictionary = msg.get("data", {})
		match event:
			"receiveRoomStart":
				var ip := str(data.get("ip", ""))
				var port := int(data.get("port", 0))
				var game_token := str(data.get("gameToken", ""))
				var player_names = data.get("playerNames", {})
				if not (player_names is Dictionary):
					player_names = {}
				emit_signal("room_start_received", port, ip, game_token, player_names)
			"roomFailed":
				emit_signal("room_failed_received")


func create_room() -> void:
	if not (await _connect_ws()):
		emit_signal("room_failed_received")
		return
	var headers = await auth_net.get_auth_header()
	var response: Dictionary = await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/create",
		HTTPClient.METHOD_POST,
		null,
		headers,
	)
	if not response.get("ok", false) or response.get("data") == null:
		emit_signal("room_failed_received")
		return
	var data: Dictionary = response["data"]
	var code := str(data.get("code", ""))
	if code.is_empty():
		push_error("Backend returned an empty room code")
		emit_signal("room_failed_received")
		return
	emit_signal("room_code_received", code)


func join_room(code: String) -> void:
	if not (await _connect_ws()):
		emit_signal("room_failed_received")
		return
	var headers = await auth_net.get_auth_header()
	var response: Dictionary = await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/join/" + code,
		HTTPClient.METHOD_POST,
		null,
		headers,
	)
	if not response.get("ok", false):
		emit_signal("room_failed_received")


func leave_room(code: String) -> void:
	if code.is_empty():
		return
	var headers = await auth_net.get_auth_header()
	var response: Dictionary = await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/leave/" + code,
		HTTPClient.METHOD_POST,
		null,
		headers,
	)
	if not response.get("ok", false):
		push_error("Failed to leave room")


func _connect_ws() -> bool:
	if socket_authed and socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return true
	socket_authed = false
	socket.close()
	socket = WebSocketPeer.new()
	socket.connect_to_url(WS_URL)
	var connect_timeout := get_tree().create_timer(WS_CONNECT_TIMEOUT)
	while socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING and connect_timeout.time_left > 0.0:
		socket.poll()
		await get_tree().process_frame
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_error("WebSocket failed to connect")
		return false
	if not await _send_auth():
		return false
	var retried_auth := false
	var auth_timeout := get_tree().create_timer(WS_AUTH_TIMEOUT)
	while auth_timeout.time_left > 0.0:
		socket.poll()
		while socket.get_available_packet_count() > 0:
			var msg = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			if not (msg is Dictionary):
				continue
			var event := str(msg.get("event", ""))
			if event == "authOk":
				socket_authed = true
				set_process(true)
				return true
			if event == "authFailed" and not retried_auth:
				retried_auth = true
				if not await _send_auth():
					return false
		await get_tree().process_frame
	push_error("WebSocket auth timed out")
	return false


func _send_auth() -> bool:
	var err := socket.send_text(JSON.stringify({
		"event": "auth",
		"data": {
			"accessToken": await auth_net.get_valid_access_token()
		}
	}))
	if err != OK:
		push_error("WebSocket auth failed to send: %s" % err)
		return false
	return true
