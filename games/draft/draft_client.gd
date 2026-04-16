extends Node

const DraftScreen = preload("res://hud/draft_screen/draft_screen.tscn")
const Overlay := preload("res://hud/overlay/overlay.tscn")

enum DraftState {
	DRAFT,
	FIGHT,
}

var state: DraftState

var map_id: String
var game_net: Node

var draft_screen: Control

@onready var hud := $Hud
@onready var logic := $Logic


func _ready() -> void:
	logic.spawn_map(map_id)
	game_net.connect("snapshot_received", logic._on_net_snapshot_received)
	game_net.connect("game_event_received", _on_net_game_event_received)


func _change_state(new_state: DraftState, data = null) -> void:
	if new_state == state:
		return
	_exit_state(new_state, data)
	_enter_state(new_state, data)
	state = new_state


func _enter_state(new_state: DraftState, data = null) -> void:
	if new_state == DraftState.DRAFT:
		var new_draft_screen = DraftScreen.instantiate()
		new_draft_screen.connect("draft_finished", _on_draft_screen_draft_finished)
		new_draft_screen.draft_options = data
		hud.add_child(new_draft_screen)
		draft_screen = new_draft_screen
	elif new_state == DraftState.FIGHT:
		var new_overlay = Overlay.instantiate()
		logic.overlay = new_overlay
		hud.add_child(new_overlay)
		logic.spawn_local_player()
		logic.set_physics_process(true)


func _exit_state(new_state: DraftState, data = null) -> void:
	for child in hud.get_children():
		child.queue_free()


func _on_draft_screen_draft_finished(draft_result: Array[int]) -> void:
	var new_game_request := GameRequest.new()
	new_game_request.type = GameRequest.Type.DRAFT_RESULT
	new_game_request.payload = draft_result
	game_net.send_game_request(new_game_request)


func _on_net_game_event_received(game_event: GameEvent) -> void:
	if game_event.type == GameEvent.Type.DRAFT_OPTIONS:
		_enter_state(DraftState.DRAFT, game_event.payload)
	elif game_event.type == GameEvent.Type.DRAFT_FINISHED:
		_change_state(DraftState.FIGHT)
