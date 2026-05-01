extends Node

const HTTP_BASE := "http://backend:8000"


func start_room(code: String) -> void:
	var data = await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/start/" + code,
		HTTPClient.METHOD_POST,
	)


func end_room(code: String) -> void:
	var data = await HttpUtils.request(
		self,
		HTTP_BASE + "/rooms/end/" + code,
		HTTPClient.METHOD_POST,
	)
