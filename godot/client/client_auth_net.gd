extends Node

signal authed

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
		emit_signal("authed")
		return
	await _refresh_session()
	emit_signal("authed")


func get_valid_access_token() -> String:
	var now := Time.get_unix_time_from_system()
	if now >= access_token_expires_at:
		await _refresh_session()
	return access_token


func get_auth_header() -> Array[String]:
	return ["Authorization: Bearer " + await get_valid_access_token()]


func _create_account() -> void:
	var data = await HttpUtils.request(
		self,
		HTTP_BASE + "/auth/guest",
		HTTPClient.METHOD_POST
	)
	
	if data == null:
		push_error("Failed to create account")
		return

	player_id = str(data.get("player_id", ""))
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	_save_refresh_token(refresh_token)


func _refresh_session() -> void:
	var data = await HttpUtils.request(
		self,
		HTTP_BASE + "/auth/refresh",
		HTTPClient.METHOD_POST,
		{
			"refresh_token": refresh_token
		}
	)
	player_id = str(data.get("player_id", ""))
	access_token = str(data.get("access_token", ""))
	refresh_token = str(data.get("refresh_token", ""))
	access_token_expires_at = Time.get_unix_time_from_system() + ACCESS_TOKEN_LIFETIME - REFRESH_MARGIN


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
