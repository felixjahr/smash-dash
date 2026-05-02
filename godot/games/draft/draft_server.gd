extends Node

signal ended

enum GameState {
	DRAFT,
	FIGHT,
	GAMEOVER,
}

var state: GameState

var map_id: String

var draft_pool: Array[Dictionary]
var draft_options_by_player_id: Dictionary[String, Array] = {}
var draft_results := {}
var gameover_ranking: Array[String] = []

@onready var backend_net := $"../Net/BackendNet"
@onready var game_net := $"../Net/GameNet"
@onready var logic := $Logic


func _ready() -> void:
	logic.spawn_map(map_id)
	game_net.connect("input_received", logic._on_net_input_received)
	game_net.connect("game_request_received", _on_net_game_request_received)
	_change_state(GameState.DRAFT)


func player_received(player_id: String) -> void:
	var draft_options: Array[Dictionary] = []
	draft_options.append(draft_pool.pop_back())
	draft_options.append(draft_pool.pop_back())
	draft_options_by_player_id[player_id] = draft_options
	game_net.send_state_sync(player_id, _build_state_sync_for(player_id))


func player_reconnected(player_id: String) -> void:
	game_net.send_state_sync(player_id, _build_state_sync_for(player_id))


func player_abandoned(player_id: String) -> void:
	if state == GameState.DRAFT:
		var ranking: Array[String] = []
		for known_player_id in draft_options_by_player_id.keys():
			if known_player_id != player_id:
				ranking.append(known_player_id)
		gameover(ranking)
		return
	logic.despawn_player(player_id)


func gameover(ranking: Array[String]) -> void:
	gameover_ranking = ranking
	_change_state(GameState.GAMEOVER, ranking)


func _change_state(new_state: GameState, data = null) -> void:
	_exit_state(data)
	state = new_state
	_enter_state(data)


func _enter_state(data = null) -> void:
	if state == GameState.DRAFT:
		draft_pool = _generate_draft_pool()
	elif state == GameState.FIGHT:
		_resolve_draft_results()
	elif state == GameState.GAMEOVER:
		logic.stop()
		for player_id in draft_options_by_player_id.keys():
			game_net.send_state_sync(player_id, _build_state_sync_for(player_id))
		emit_signal("ended")


func _exit_state(data = null) -> void:
	pass


func _generate_draft_pool() -> Array[Dictionary]:
	var category_ids := [
		"weapon",
		"weapon",
		"armour",
		"ability",
	]
	category_ids.shuffle()

	var remaining_ids_by_category := {}
	for category_id in category_ids:
		if remaining_ids_by_category.has(category_id):
			continue
		var ids: Array = Data.CATEGORIES[category_id].keys().duplicate()
		ids.shuffle()
		remaining_ids_by_category[category_id] = ids

	var pool: Array[Dictionary] = []
	for category_id in category_ids:
		var remaining_ids: Array = remaining_ids_by_category[category_id]
		var option_ids := [
			remaining_ids.pop_back(),
			remaining_ids.pop_back(),
		]
		pool.append({
			"category_id": category_id,
			"option_ids": option_ids,
		})
	return pool


func _resolve_draft_results() -> void:
	var player_ids := draft_results.keys()
	var player_id_a: String = player_ids[0]
	var player_id_b: String = player_ids[1]
	
	var loadouts: Dictionary[String, Dictionary] = {
		player_id_a: {
			"weapon_ids": [] as Array[String],
			"armour_id": "",
			"ability_ids": [] as Array[String],
		},
		player_id_b: {
			"weapon_ids": [] as Array[String],
			"armour_id": "",
			"ability_ids": [] as Array[String],
		},
	}
	
	for player_id in player_ids:
		var other_player_id := player_id_b if player_id == player_id_a else player_id_a
		var draft_options = draft_options_by_player_id[player_id]
		var draft_result = draft_results[player_id]
		
		for pick in draft_result:
			if pick < 0 or pick > 1:
				pick = 0
			var other_pick = 0 if pick == 1 else 1
			var draft_option = draft_options.pop_front()
			var category_id = draft_option["category_id"]
			var option_ids = draft_option["option_ids"]
			match category_id:
				"weapon":
					loadouts[player_id]["weapon_ids"].append(option_ids[pick])
					loadouts[other_player_id]["weapon_ids"].append(option_ids[other_pick])
				"armour":
					loadouts[player_id]["armour_id"] = option_ids[pick]
					loadouts[other_player_id]["armour_id"] = option_ids[other_pick]
				"ability":
					loadouts[player_id]["ability_ids"].append(option_ids[pick])
					loadouts[other_player_id]["ability_ids"].append(option_ids[other_pick])
	
	for player_id in player_ids:
		logic.spawn_player(player_id, loadouts[player_id]["weapon_ids"], loadouts[player_id]["armour_id"])
		logic.start()
		game_net.send_state_sync(player_id, _build_state_sync_for(player_id))


func _build_state_sync_for(player_id: String) -> StateSync:
	var state_sync := StateSync.new()
	state_sync.phase = state
	var payload := {}
	match state:
		GameState.DRAFT:
			payload = {
				"draft_options": draft_options_by_player_id.get(player_id, []),
				"draft_submitted": draft_results.has(player_id),
			}
		GameState.GAMEOVER:
			payload = {
				"ranking": gameover_ranking,
			}
	state_sync.payload = payload
	return state_sync


func _on_net_game_request_received(player_id: String, game_request: GameRequest) -> void:
	if state != GameState.DRAFT:
		return
	if game_request.type != GameRequest.Type.DRAFT_RESULT:
		return
	if draft_results.has(player_id):
		game_net.send_state_sync(player_id, _build_state_sync_for(player_id))
		return
	
	draft_results[player_id] = game_request.payload
	
	if draft_results.size() == 2:
		_change_state(GameState.FIGHT)
	else:
		game_net.send_state_sync(player_id, _build_state_sync_for(player_id))
