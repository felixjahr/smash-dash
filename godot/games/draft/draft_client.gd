extends Node

signal ended
signal match_over

const DraftScreen = preload("res://ui/draft_screen/draft_screen.tscn")
const Overlay := preload("res://ui/overlay/overlay.tscn")
const Gameover := preload("res://ui/gameover/gameover.tscn")
const Loading := preload("res://ui/loading/loading.tscn")

enum GameState {
	DRAFT,
	FIGHT,
	GAMEOVER,
}

var state: GameState

var map_id: String

var draft_screen: Control

@onready var ui := $"../UI"
@onready var game_net := $"../Net/GameNet"
@onready var logic := $Logic


func _ready() -> void:
	logic.spawn_map(map_id)
	game_net.connect("snapshot_received", _on_net_snapshot_received)
	game_net.connect("state_sync_received", _on_net_state_sync_received)


func _change_state(new_state: GameState, data = null) -> void:
	_exit_state(data)
	state = new_state
	_enter_state(data)


func _enter_state(data = null) -> void:
	if state == GameState.DRAFT:
		if data["draft_submitted"]:
			var new_loading = Loading.instantiate()
			ui.add_child(new_loading)
			return
		var new_draft_screen = DraftScreen.instantiate()
		new_draft_screen.connect("draft_finished", _on_draft_screen_draft_finished)
		new_draft_screen.draft_options = data["draft_options"]
		ui.add_child(new_draft_screen)
		draft_screen = new_draft_screen
	elif state == GameState.FIGHT:
		var new_overlay = Overlay.instantiate()
		logic.overlay = new_overlay
		ui.add_child(new_overlay)
		logic.start()
	elif state == GameState.GAMEOVER:
		logic.stop()
		emit_signal("match_over")
		var new_gameover = Gameover.instantiate()
		new_gameover.ranking = data["ranking"]
		ui.add_child(new_gameover)
		new_gameover.continue_button.connect("pressed", _on_gameover_continue_pressed)


func _exit_state(data = null) -> void:
	for child in ui.get_children():
		child.queue_free()
	draft_screen = null


func _on_net_state_sync_received(state_sync: StateSync) -> void:
	_change_state(state_sync.phase, state_sync.payload)


func _on_net_snapshot_received(snapshot: Snapshot) -> void:
	if state != GameState.FIGHT:
		return
	logic.snapshot_received(snapshot)


func _on_draft_screen_draft_finished(draft_result: Array[int]) -> void:
	var new_game_request := GameRequest.new()
	new_game_request.type = GameRequest.Type.DRAFT_RESULT
	new_game_request.payload = draft_result
	game_net.send_game_request(new_game_request)


func _on_gameover_continue_pressed() -> void:
	emit_signal("ended")
