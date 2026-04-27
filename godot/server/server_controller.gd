extends Node

const GAMES: Dictionary[String, PackedScene] = {
	"draft": preload("res://games/draft/draft_server.tscn"),
}

const RECONNECT_TIMEOUT := 10

var game_id: String
var map_id: String
var code: String

var allowed_players: Dictionary
var disconnected_players: Dictionary[String, float]
var player_id_by_pid: Dictionary[int, String]
var pid_by_player_id: Dictionary[String, int]

var game: Node

@onready var backend_net := $Net/BackendNet
@onready var game_net := $Net/GameNet


func _ready() -> void:
	multiplayer.connect("peer_disconnected", _on_peer_diconnected)
	
	var args := _get_cmdline_params()
	var port := int(args["port"])
	game_id = args["game_id"]
	map_id = args["map_id"]
	code = args["code"]
	allowed_players = JSON.parse_string(args["allowed_players"])
	
	var new_game := GAMES[game_id].instantiate()
	new_game.map_id = map_id
	add_child(new_game)
	new_game.connect("ended", _on_game_ended)
	game = new_game
	
	game_net.connect("game_token_received", _on_net_game_token_received)
	game_net.create_server(port)
	backend_net.start_room(code)


func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	for player_id in disconnected_players.keys():
		if now - disconnected_players[player_id] >= RECONNECT_TIMEOUT:
			disconnected_players.erase(player_id)
			game.player_abandoned(player_id)


func _on_net_game_token_received(pid: int, game_token: String) -> void:
	var token_hash := _hash_token(game_token)
	if not allowed_players.has(token_hash):
		multiplayer.multiplayer_peer.disconnect_peer(pid)
		return
	var player_id: String = allowed_players[token_hash]
	pid_by_player_id[player_id] = pid
	player_id_by_pid[pid] = player_id
	if disconnected_players.has(player_id):
		disconnected_players.erase(player_id)
		return
	game_net.send_init(player_id, game_id, map_id)
	game.player_received(player_id)


func _on_peer_diconnected(pid: int) -> void:
	var player_id := player_id_by_pid[pid]
	player_id_by_pid.erase(pid)
	pid_by_player_id.erase(player_id)
	disconnected_players[player_id] = Time.get_unix_time_from_system()


func _on_game_ended() -> void:
	backend_net.end_room(code)


func _get_cmdline_params() -> Dictionary:
	var params := {}
	for arg in OS.get_cmdline_args():
		if "=" not in arg:
			continue
		var parts := arg.split("=")
		if parts.size() != 2:
			continue
		params[parts[0]] = parts[1]
	return params 


func _hash_token(token: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(token.to_utf8_buffer())
	return ctx.finish().hex_encode()
