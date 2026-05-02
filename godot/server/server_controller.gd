extends Node

const GAMES: Dictionary[String, PackedScene] = {
	"draft": preload("res://games/draft/draft_server.tscn"),
}

const RECONNECT_TIMEOUT := 10
const SHUTDOWN_GRACE_SECONDS := 2.0

var game_id: String
var map_id: String
var code: String

var disconnected_players: Dictionary[String, float] = {}
var known_players: Dictionary[String, bool] = {}
var match_ending := false

var game: Node

@onready var backend_net := $Net/BackendNet
@onready var game_net := $Net/GameNet


func _ready() -> void:
	var args := _get_cmdline_params()
	for key in ["port", "game_id", "map_id", "code", "allowed_players", "server_callback_secret"]:
		if not args.has(key) or str(args[key]).is_empty():
			push_error("Missing required server argument: %s" % key)
			get_tree().quit(1)
			return
	var port := int(args["port"])
	game_id = str(args["game_id"])
	map_id = str(args["map_id"])
	code = str(args["code"])
	backend_net.server_callback_secret = str(args["server_callback_secret"])
	if not GAMES.has(game_id):
		push_error("Unknown game id: %s" % game_id)
		get_tree().quit(1)
		return
	if not Data.MAPS.has(map_id):
		push_error("Unknown map id: %s" % map_id)
		get_tree().quit(1)
		return
	var parsed_allowed_players = JSON.parse_string(str(args["allowed_players"]))
	if not (parsed_allowed_players is Dictionary):
		push_error("Invalid allowed_players argument")
		get_tree().quit(1)
		return
	
	var new_game := GAMES[game_id].instantiate()
	new_game.map_id = map_id
	add_child(new_game)
	new_game.connect("ended", _on_game_ended)
	game = new_game
	
	game_net.allowed_players = parsed_allowed_players
	game_net.connect("player_authenticated", _on_net_player_authenticated)
	game_net.connect("player_disconnected", _on_net_player_disconnected)
	game_net.create_server(port)
	if not (await backend_net.start_room(code)):
		push_error("Failed to notify backend that room started")
		get_tree().quit(1)


func _process(_delta: float) -> void:
	if match_ending:
		return
	var now := Time.get_unix_time_from_system()
	var abandoned_player_id := ""
	var abandoned_at := INF
	for player_id in disconnected_players.keys():
		if now - disconnected_players[player_id] >= RECONNECT_TIMEOUT:
			if disconnected_players[player_id] < abandoned_at:
				abandoned_at = disconnected_players[player_id]
				abandoned_player_id = player_id
	if abandoned_player_id.is_empty():
		return
	disconnected_players.erase(abandoned_player_id)
	known_players.erase(abandoned_player_id)
	game.player_abandoned(abandoned_player_id)


func _on_net_player_authenticated(player_id: String) -> void:
	var player_was_known := known_players.has(player_id)
	known_players[player_id] = true
	if player_was_known:
		disconnected_players.erase(player_id)
		game_net.send_init(player_id, game_id, map_id)
		game.player_reconnected(player_id)
		return
	game_net.send_init(player_id, game_id, map_id)
	game.player_received(player_id)


func _on_net_player_disconnected(player_id: String) -> void:
	if not known_players.has(player_id):
		return
	disconnected_players[player_id] = Time.get_unix_time_from_system()


func _on_game_ended() -> void:
	if match_ending:
		return
	match_ending = true
	await get_tree().create_timer(SHUTDOWN_GRACE_SECONDS).timeout
	await backend_net.end_room(code)
	get_tree().quit()


func _get_cmdline_params() -> Dictionary:
	var params := {}
	for arg in OS.get_cmdline_args():
		if "=" not in arg:
			continue
		var separator_index := arg.find("=")
		if separator_index <= 0:
			continue
		params[arg.substr(0, separator_index)] = arg.substr(separator_index + 1)
	return params
