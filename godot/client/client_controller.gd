extends Node

enum ClientState {
	LOADING,
	HOME,
	OPTIONS,
	CREATING,
	CREATE,
	
	JOIN,
	JOINING,
	
	CONNECTING,
	GAME,
}

const GAMES: Dictionary[String, PackedScene] = {
	"draft": preload("res://games/draft/draft_client.tscn"),
}

const Loading := preload("res://ui/loading/loading.tscn")
const Home := preload("res://ui/home/home.tscn")
const Options := preload("res://ui/options/options.tscn")
const Create := preload("res://ui/create/create.tscn")
const Join := preload("res://ui/join/join.tscn")

var state: ClientState

var game: Node

@onready var auth_net := $Net/AuthNet
@onready var backend_net := $Net/BackendNet
@onready var game_net := $Net/GameNet
@onready var ui := $UI


func _ready() -> void:
	auth_net.connect("authed", _on_net_authed)
	backend_net.connect("room_code_received", _on_net_room_code_received)
	backend_net.connect("room_start_received", _on_net_room_start_received)
	game_net.connect("init_received", _on_net_init_received)
	_enter_state(ClientState.LOADING)


func _change_state(new_state: ClientState, data = null) -> void:
	_exit_state(data)
	state = new_state
	_enter_state(data)


func _enter_state(data = null) -> void:
	if state == ClientState.LOADING:
		var new_loading := Loading.instantiate()
		ui.add_child(new_loading)
	elif state == ClientState.HOME:
		var new_home := Home.instantiate()
		ui.add_child(new_home)
		new_home.create_button.connect("pressed", _on_home_create_pressed)
		new_home.join_button.connect("pressed", _on_home_join_pressed)
		new_home.options_button.connect("pressed", _on_home_options_pressed)
		new_home.name_label.text = auth_net.player_id
	elif state == ClientState.OPTIONS:
		var new_options := Options.instantiate()
		ui.add_child(new_options)
		new_options.back_button.connect("pressed", _on_options_back_pressed)
	elif state == ClientState.CREATING:
		var new_loading := Loading.instantiate()
		ui.add_child(new_loading)
		backend_net.create_room()
	elif state == ClientState.CREATE:
		var new_create := Create.instantiate()
		ui.add_child(new_create)
		new_create.code.text = data
	elif state == ClientState.JOIN:
		var new_join := Join.instantiate()
		ui.add_child(new_join)
		new_join.submit_button.connect("pressed", _on_join_submit_pressed)
	elif state == ClientState.JOINING:
		var new_loading := Loading.instantiate()
		ui.add_child(new_loading)
		backend_net.join_room(data)
	elif state == ClientState.CONNECTING:
		var new_loading := Loading.instantiate()
		ui.add_child(new_loading)
		game_net.create_client(data["port"], data["ip"])
		await multiplayer.connected_to_server
		game_net.send_game_token(data["game_token"])
	elif state == ClientState.GAME:
		var new_game := GAMES[data["game_id"]].instantiate()
		new_game.map_id = data["map_id"]
		add_child(new_game)
		new_game.connect("ended", _on_game_ended)
		game = new_game


func _exit_state(data = null) -> void:
	if state == ClientState.GAME:
		game.queue_free()
	for child in ui.get_children():
		child.queue_free()


func _on_account_create_pressed() -> void:
	auth_net.create_account()
	_change_state(ClientState.LOADING)


func _on_net_authed() -> void:
	_change_state(ClientState.HOME)


func _on_home_options_pressed() -> void:
	_change_state(ClientState.OPTIONS)


func _on_options_back_pressed() -> void:
	_change_state(ClientState.HOME)


func _on_home_create_pressed() -> void:
	_change_state(ClientState.CREATING)


func _on_net_room_code_received(code: String) -> void:
	_change_state(ClientState.CREATE, code)


func _on_home_join_pressed() -> void:
	_change_state(ClientState.JOIN)


func _on_join_submit_pressed() -> void:
	_change_state(ClientState.JOINING, ui.get_child(0).code.text)


func _on_net_room_start_received(port: int, ip: String, game_token: String) -> void:
	_change_state(ClientState.CONNECTING, {
		"port" : port,
		"ip" : ip,
		"game_token" : game_token
	})


func _on_net_init_received(game_id: String, map_id: String) -> void:
	_change_state(ClientState.GAME, {
		"game_id" : game_id,
		"map_id" : map_id,
	})


func _on_game_ended() -> void:
	_change_state(ClientState.HOME)
