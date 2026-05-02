extends Node

signal authed
signal auth_failed

const HTTP_BASE := "http://34.159.203.1:8000"
const ACCESS_TOKEN_LIFETIME := 900
const REFRESH_MARGIN := 30

var player_id := ""
var access_token := ""
var refresh_token := ""
var access_token_expires_at := 0.0


func _ready() -> void:
	refresh_token = _load_refresh_token()
	if refresh_token.is_empty():
		await _create_account()
		if not access_token.is_empty():
			emit_signal("authed")
		else:
			emit_signal("auth_failed")
		return
	if not (await _refresh_session()):
		refresh_token = ""
		await _create_account()
	if not access_token.is_empty():
		emit_signal("authed")
	else:
		emit_signal("auth_failed")


func get_valid_access_token() -> String:
	var now := Time.get_unix_time_from_system()
	if now >= access_token_expires_at:
		if not (await _refresh_session()):
			await _create_account()
	return access_token


func get_auth_header() -> Array[String]:
	var token := await get_valid_access_token()
	return ["Authorization: Bearer " + token]


func _create_account() -> bool:
	var response: Dictionary = await HttpUtils.request(
		self,
		HTTP_BASE + "/auth/guest",
		HTTPClient.METHOD_POST
	)
	
	if not response.get("ok", false) or response.get("data") == null:
		push_error("Failed to create account")
		return false
	var data: Dictionary = response["data"]
	player_id = str(data.get("player_id", ""))
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	access_token_expires_at = Time.get_unix_time_from_system() + ACCESS_TOKEN_LIFETIME - REFRESH_MARGIN
	_save_refresh_token(refresh_token)
	return not player_id.is_empty() and not access_token.is_empty() and not refresh_token.is_empty()


func _refresh_session() -> bool:
	var response: Dictionary = await HttpUtils.request(
		self,
		HTTP_BASE + "/auth/refresh",
		HTTPClient.METHOD_POST,
		{
			"refresh_token": refresh_token
		}
	)
	if not response.get("ok", false) or response.get("data") == null:
		push_error("Failed to refresh session")
		return false
	var data: Dictionary = response["data"]
	player_id = str(data.get("player_id", ""))
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	access_token_expires_at = Time.get_unix_time_from_system() + ACCESS_TOKEN_LIFETIME - REFRESH_MARGIN
	return not player_id.is_empty() and not access_token.is_empty() and not refresh_token.is_empty()


func _save_refresh_token(token: String) -> void:
	# Debug only
	var suffix := ""
	if OS.has_feature("1"):
		suffix = "1"
	elif OS.has_feature("2"):
		suffix = "2"
	elif OS.has_feature("3"):
		suffix = "3"
	elif OS.has_feature("4"):
		suffix = "4"
	
	var cfg := ConfigFile.new()
	cfg.set_value("auth", "refresh_token", token)
	cfg.save("user://session" + suffix + ".cfg")


func _load_refresh_token() -> String:
	# Debug only
	var suffix := ""
	if OS.has_feature("1"):
		suffix = "1"
	elif OS.has_feature("2"):
		suffix = "2"
	elif OS.has_feature("3"):
		suffix = "3"
	elif OS.has_feature("4"):
		suffix = "4"
	
	var cfg := ConfigFile.new()	
	var err := cfg.load("user://session" + suffix + ".cfg")
	if err != OK:
		return ""
	return str(cfg.get_value("auth", "refresh_token", ""))
