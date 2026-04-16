extends Node

enum DraftState {
	DRAFT,
	FIGHT,
}

var state: DraftState

var game_id: String
var map_id: String
var game_net: Node

var draft_pool: Array[Dictionary]
var draft_options_by_pid: Dictionary[int, Array] = {}
var draft_results := {}

@onready var logic := $Logic


func _ready() -> void:
	logic.spawn_map(map_id)
	game_net.connect("input_received", logic._on_net_input_received)
	game_net.connect("game_request_received", _on_net_game_request_received)
	game_net.connect("peer_connected", _on_net_peer_connected)
	_enter_state(DraftState.DRAFT)


func _change_state(new_state: DraftState) -> void:
	if new_state == state:
		return
	_exit_state(new_state)
	_enter_state(new_state)
	state = new_state


func _enter_state(new_state: DraftState) -> void:
	if new_state == DraftState.DRAFT:
		draft_pool = _generate_draft_pool()
	elif new_state == DraftState.FIGHT:
		_resolve_draft_results()


func _exit_state(new_state: DraftState) -> void:
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
	var pids := draft_results.keys()
	var pid_a: int = pids[0]
	var pid_b: int = pids[1]
	
	var loadouts: Dictionary[int, Dictionary] = {
		pid_a: {
			"weapon_ids": [] as Array[String],
			"armour_id": "",
			"ability_ids": [] as Array[String],
		},
		pid_b: {
			"weapon_ids": [] as Array[String],
			"armour_id": "",
			"ability_ids": [] as Array[String],
		},
	}
	
	for pid in pids:
		var other_pid := pid_b if pid == pid_a else pid_a
		var draft_options = draft_options_by_pid[pid]
		var draft_result = draft_results[pid]
		
		for pick in draft_result:
			if pick < 0 or pick > 1:
				pick = 0
			var other_pick = 0 if pick == 1 else 1
			var draft_option = draft_options.pop_front()
			var category_id = draft_option["category_id"]
			var option_ids = draft_option["option_ids"]
			match category_id:
				"weapon":
					loadouts[pid]["weapon_ids"].append(option_ids[pick])
					loadouts[other_pid]["weapon_ids"].append(option_ids[other_pick])
				"armour":
					loadouts[pid]["armour_id"] = option_ids[pick]
					loadouts[other_pid]["armour_id"] = option_ids[other_pick]
				"ability":
					loadouts[pid]["ability_ids"].append(option_ids[pick])
					loadouts[other_pid]["ability_ids"].append(option_ids[other_pick])
	
	for pid in pids:
		logic.spawn_player(pid, loadouts[pid]["weapon_ids"], loadouts[pid]["armour_id"])
		var new_game_event := GameEvent.new()
		new_game_event.type = GameEvent.Type.DRAFT_FINISHED
		game_net.send_game_event(pid, new_game_event)


func _on_net_game_request_received(pid: int, game_request: GameRequest) -> void:
	if game_request.type != GameRequest.Type.DRAFT_RESULT:
		return
	
	draft_results[pid] = game_request.payload
	
	if draft_results.size() == 2:
		_change_state(DraftState.FIGHT)


func _on_net_peer_connected(pid: int) -> void:
	print(pid)
	var new_init := Init.new()
	new_init.game_id = game_id
	new_init.map_id = map_id
	game_net.send_init(pid, new_init)
	
	var draft_options: Array[Dictionary] = []
	draft_options.append(draft_pool.pop_back())
	draft_options.append(draft_pool.pop_back())
	draft_options_by_pid[pid] = draft_options
	
	var new_game_event := GameEvent.new()
	new_game_event.type = GameEvent.Type.DRAFT_OPTIONS
	new_game_event.payload = draft_options
	game_net.send_game_event(pid, new_game_event)
