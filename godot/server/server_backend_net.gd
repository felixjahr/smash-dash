extends Node

const HTTP_BASE := "http://backend:8000"
const REQUEST_ATTEMPTS := 5

var server_callback_secret: String


func start_room(code: String) -> bool:
	for attempt in REQUEST_ATTEMPTS:
		var response: Dictionary = await HttpUtils.request(
			self,
			HTTP_BASE + "/rooms/start/" + code,
			HTTPClient.METHOD_POST,
			null,
			["x-server-secret: " + server_callback_secret]
		)
		if response.get("ok", false):
			return true
		if attempt < REQUEST_ATTEMPTS - 1:
			await get_tree().create_timer(1.0).timeout
	return false


func end_room(code: String) -> bool:
	for attempt in REQUEST_ATTEMPTS:
		var response: Dictionary = await HttpUtils.request(
			self,
			HTTP_BASE + "/rooms/end/" + code,
			HTTPClient.METHOD_POST,
			null,
			["x-server-secret: " + server_callback_secret]
		)
		if response.get("ok", false):
			return true
		if attempt < REQUEST_ATTEMPTS - 1:
			await get_tree().create_timer(1.0).timeout
	return false
