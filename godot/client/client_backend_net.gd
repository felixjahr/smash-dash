extends Node

signal room_code_received(code: String)
signal room_start_received(port: int, ip: String, game_token: String)

const HTTP_BASE := "http://34.159.203.1:8000"

const WS_URL := "ws://34.159.203.1:8000/ws"
var socket := WebSocketPeer.new()

@onready var auth_net := $"../AuthNet"


func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	socket.poll()
	while socket.get_available_packet_count() > 0:
		var msg = JSON.parse_string(socket.get_packet().get_string_from_utf8())
		var event := str(msg.get("event", ""))
		var data: Dictionary = msg.get("data", {})
		match event:
			"receiveRoomStart":
				var ip := str(data.get("ip", ""))
				var port := int(data.get("port", 0))
				var game_token := str(data.get("gameToken", ""))
				emit_signal("room_start_received", port, ip, game_token)


func create_room() -> void:
	await _connect_ws()
	var data = await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/create",
		HTTPClient.METHOD_POST,
		null,
		auth_net.get_auth_header()
	)
	emit_signal("room_code_received", data.code)


func join_room(code: String) -> void:
	await _connect_ws()
	await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/join/" + code,
		HTTPClient.METHOD_POST,
		null,
		auth_net.get_auth_header()
	)


func _connect_ws() -> void:
	socket.connect_to_url(WS_URL)
	while socket.get_ready_state() == WebSocketPeer.STATE_CONNECTING:
		socket.poll()
		await get_tree().process_frame
	if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		push_error("WebSocket failed to connect")
	await socket.send_text(JSON.stringify({
		"event": "auth",
		"data": {
			"accessToken": auth_net.get_valid_access_token()
		}
	}))
	while true:
		socket.poll()
		while socket.get_available_packet_count() > 0:
			var msg = JSON.parse_string(socket.get_packet().get_string_from_utf8())
			var event := str(msg.get("event", ""))
			if event == "authOk":
				set_process(true)
				return
		await get_tree().process_frame
