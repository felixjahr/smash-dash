extends Node

const TICK_RATE := 60.0
const INPUT_LEAD := 5
const SNAPSHOT_BUFFER_SIZE := 128
const INPUT_BUFFER_SIZE := 128

const PlayerClient := preload("res://player/player_client.tscn")
const BulletClient := preload("res://bullet/bullet_client.tscn")

var estimated_server_tick: float
var last_snapshot_tick := -1

var players: Dictionary[int, Node2D] = {}
var bullets: Dictionary[int, Node2D] = {}

var snapshots: Array[Snapshot]
var inputs: Array[PlayerInput]

var overlay: Control
var map

@onready var map_container := $MapContainer
@onready var remote_player_container := $RemotePlayerContainer
@onready var local_player_container := $LocalPlayerContainer
@onready var bullet_container := $BulletContainer


func _ready() -> void:
	snapshots.resize(SNAPSHOT_BUFFER_SIZE)
	inputs.resize(INPUT_BUFFER_SIZE)
	set_physics_process(false)


func spawn_map(map_id: String) -> void:
	var new_map := Data.MAPS[map_id].instantiate()
	map_container.add_child(new_map)
	map = new_map


func spawn_local_player() -> void: # TODO: Get rid of this
	var local_pid := multiplayer.get_unique_id()
	var new_player := PlayerClient.instantiate()
	new_player.name = str(local_pid)
	new_player.local = true
	new_player.camera = map.camera
	local_player_container.add_child(new_player)
	players[local_pid] = new_player


func _physics_process(delta: float) -> void:
	estimated_server_tick += delta * TICK_RATE
	
	overlay.poll()
	var input := PlayerInput.new()
	input.tick = int(estimated_server_tick) + INPUT_LEAD
	input.direction = Input.get_axis("move_left", "move_right")
	input.jumping = Input.is_action_pressed("jump")
	input.current_weapon = overlay.current_weapon
	input.weapon_aim_directions = overlay.weapon_aim_directions
	inputs[input.tick % INPUT_BUFFER_SIZE] = input
	get_parent().game_net.send_input(input)


func _on_net_snapshot_received(snapshot: Snapshot) -> void:
	snapshots[snapshot.tick % SNAPSHOT_BUFFER_SIZE] = snapshot
	
	if snapshot.tick < last_snapshot_tick:
		return
	last_snapshot_tick = snapshot.tick
	estimated_server_tick = snapshot.tick
	
	_apply_entity_snapshots(
		players,
		snapshot.players,
		func(player_snapshot): return player_snapshot.pid,
		func(pid):
			var player = PlayerClient.instantiate()
			player.name = str(pid)
			remote_player_container.add_child(player)
			return player
	)
	
	_apply_entity_snapshots(
		bullets,
		snapshot.bullets,
		func(bullet_snapshot): return bullet_snapshot.bullet_id,
		func(bullet_id):
			var bullet = BulletClient.instantiate()
			bullet.name = str(bullet_id)
			bullet_container.add_child(bullet)
			return bullet
	)


func _apply_entity_snapshots(entities: Dictionary, entity_snapshots: Array, get_id: Callable, create_entity: Callable) -> void:
	var snapshot_ids := entity_snapshots.map(get_id)
	for id in entities.keys():
		if not snapshot_ids.has(id):
			entities[id].queue_free()
			entities.erase(id)
	for id in snapshot_ids:
		if not entities.has(id):
			var entity = create_entity.call(id)
			entities[id] = entity
	
	for entity_snapshot in entity_snapshots:
		var id: int = get_id.call(entity_snapshot)
		entities[id].apply_snapshot(entity_snapshot)
