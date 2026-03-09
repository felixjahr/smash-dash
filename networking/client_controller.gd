extends Node

enum ClientState {
	HOMESCREEN,
	OPTIONS,
	MATCH,
}

const Homescreen := preload("res://menus/homescreen/homescreen.tscn")
const Options := preload("res://menus/options/options.tscn")
const Overlay := preload("res://menus/overlay/overlay.tscn")

var state: ClientState

@onready var ui := $UI
@onready var view = $View


func _ready() -> void:
	_enter_state(ClientState.HOMESCREEN)


func _change_state(new_state: ClientState) -> void:
	if new_state == state:
		return
	_exit_state(new_state)
	_enter_state(new_state)
	state = new_state


func _enter_state(new_state: ClientState) -> void:
	if new_state == ClientState.HOMESCREEN:
		var new_homescreen = Homescreen.instantiate()
		ui.add_child(new_homescreen)
		new_homescreen.play_button.connect("pressed", _on_homescreen_play_pressed)
		new_homescreen.options_button.connect("pressed", _on_homescreen_options_pressed)
	elif new_state == ClientState.OPTIONS:
		var new_options = Options.instantiate()
		ui.add_child(new_options)
		new_options.back_button.connect("pressed", _on_options_back_pressed)
	elif new_state == ClientState.MATCH:
		var new_overlay = Overlay.instantiate()
		ui.add_child(new_overlay)
		view.overlay = new_overlay
		view.start_match()


func _exit_state(new_state: ClientState) -> void:
	for child in ui.get_children():
		child.queue_free()


func _on_homescreen_play_pressed() -> void:
	_change_state(ClientState.MATCH)


func _on_homescreen_options_pressed() -> void:
	_change_state(ClientState.OPTIONS)


func _on_options_back_pressed() -> void:
	_change_state(ClientState.HOMESCREEN)
