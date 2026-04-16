extends Node

enum ClientState {
	HOME,
	OPTIONS,
	CREATE,
	JOIN,
	CONNECTING,
	GAME,
}

const BACKEND_IP := "127.0.0.1"
#const BACKEND_IP := "35.198.127.12"
const BACKEND_PORT := 8000

const GAMES: Dictionary[String, PackedScene] = {
	"draft": preload("res://games/draft/draft_client.tscn"),
}

const Home := preload("res://ui/home/home.tscn")
const Options := preload("res://ui/options/options.tscn")
const Create := preload("res://ui/create/create.tscn")
const Join := preload("res://ui/join/join.tscn")

var state: ClientState

var game: Node

@onready var backend_net := $Net/BackendNet
@onready var game_net := $Net/GameNet
@onready var ui := $UI


func _ready() -> void:
	backend_net.connect("room_code_received", _on_net_room_code_received)
	backend_net.connect("room_start_received", _on_net_room_start_received)
	game_net.connect("init_received", _on_net_init_received)
	_enter_state(ClientState.HOME)


func _change_state(new_state: ClientState, data = null) -> void:
	if new_state == state:
		return
	_exit_state(new_state, data)
	_enter_state(new_state, data)
	state = new_state


func _enter_state(new_state: ClientState, data = null) -> void:
	if new_state == ClientState.HOME:
		var new_home := Home.instantiate()
		ui.add_child(new_home)
		new_home.create_button.connect("pressed", _on_home_create_pressed)
		new_home.join_button.connect("pressed", _on_home_join_pressed)
		new_home.options_button.connect("pressed", _on_home_options_pressed)
	elif new_state == ClientState.OPTIONS:
		var new_options := Options.instantiate()
		ui.add_child(new_options)
		new_options.back_button.connect("pressed", _on_options_back_pressed)
	elif new_state == ClientState.CREATE:
		var new_create := Create.instantiate()
		ui.add_child(new_create)
		backend_net.create_client(BACKEND_PORT, BACKEND_IP)
		await multiplayer.connected_to_server
		backend_net.send_create_room()
	elif new_state == ClientState.JOIN:
		var new_join := Join.instantiate()
		ui.add_child(new_join)
		new_join.submit_button.connect("pressed", _on_join_submit_pressed)
		backend_net.create_client(BACKEND_PORT, BACKEND_IP)


func _exit_state(new_state: ClientState, data = null) -> void:
	for child in ui.get_children():
		child.queue_free()


func _on_home_create_pressed() -> void:
	_change_state(ClientState.CREATE)


func _on_home_join_pressed() -> void:
	_change_state(ClientState.JOIN)


func _on_home_options_pressed() -> void:
	_change_state(ClientState.OPTIONS)


func _on_options_back_pressed() -> void:
	_change_state(ClientState.HOME)


func _on_join_submit_pressed() -> void:
	var code: String = ui.get_child(0).code.text
	backend_net.send_join_room(code)


func _on_net_room_code_received(code: String) -> void:
	if state == ClientState.CREATE:
		ui.get_child(0).code.text = code


func _on_net_room_start_received(port: int, ip: String) -> void:
	_change_state(ClientState.CONNECTING)
	await get_tree().create_timer(2.0).timeout
	game_net.create_client(port, ip)


func _on_net_init_received(init: Init) -> void:
	_change_state(ClientState.GAME)
	var new_game := GAMES[init.game_id].instantiate()
	new_game.map_id = init.map_id
	new_game.game_net = game_net
	add_child(new_game)
	game = new_game
