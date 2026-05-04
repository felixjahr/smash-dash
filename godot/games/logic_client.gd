extends Node

const TICK_RATE := 60.0
const INPUT_LEAD := 5
const INTERPOLATION_DELAY_TICKS := 5
const CLOCK_SNAP_THRESHOLD_TICKS := 15.0
const CLOCK_CORRECTION_FACTOR := 0.2
const SNAPSHOT_BUFFER_SIZE := 128
const INPUT_BUFFER_SIZE := 128

const PlayerClient := preload("res://player/player_client.tscn")
const BulletClient := preload("res://bullet/bullet_client.tscn")

var estimated_server_tick: float
var last_snapshot_tick := -1
var received_first_snapshot := false

var players: Dictionary[String, Node2D] = {}
var bullets: Dictionary[String, Node2D] = {}

var snapshots: Array[Snapshot]
var inputs: Array[PlayerInput]

var overlay: Control
var map: Node2D

var player_names: Dictionary = {}

@onready var game_net := $"../../Net/GameNet"
@onready var map_container := $MapContainer
@onready var player_container := $PlayerContainer
@onready var bullet_container := $BulletContainer


func _ready() -> void:
	snapshots.resize(SNAPSHOT_BUFFER_SIZE)
	inputs.resize(INPUT_BUFFER_SIZE)
	stop()


func _physics_process(delta: float) -> void:
	estimated_server_tick += delta * TICK_RATE
	
	overlay.poll()
	var input := PlayerInput.new()
	input.tick = int(estimated_server_tick) + INPUT_LEAD
	input.direction = overlay.direction
	input.jumping = overlay.jumping
	input.current_weapon = overlay.current_weapon
	input.weapon_aim_directions = overlay.weapon_aim_directions
	inputs[input.tick % INPUT_BUFFER_SIZE] = input
	game_net.send_input(input)
	
	_render_interpolated_snapshot()


func start() -> void:
	set_physics_process(true)


func stop() -> void:
	set_physics_process(false)


func spawn_map(map_id: String) -> void:
	var new_map := Data.MAPS[map_id].instantiate()
	map_container.add_child(new_map)
	map = new_map


func snapshot_received(snapshot: Snapshot) -> void:
	if snapshot.tick < last_snapshot_tick:
		return
	last_snapshot_tick = snapshot.tick
	snapshots[snapshot.tick % SNAPSHOT_BUFFER_SIZE] = snapshot
	
	if not received_first_snapshot:
		received_first_snapshot = true
		estimated_server_tick = snapshot.tick
		return
	
	var clock_error := float(snapshot.tick) - estimated_server_tick
	if absf(clock_error) > CLOCK_SNAP_THRESHOLD_TICKS:
		estimated_server_tick = snapshot.tick
	else:
		estimated_server_tick += clock_error * CLOCK_CORRECTION_FACTOR


func _render_interpolated_snapshot() -> void:
	if not received_first_snapshot:
		return
	var render_tick := estimated_server_tick - INTERPOLATION_DELAY_TICKS
	var render_snapshot: Snapshot = _build_interpolated_snapshot(render_tick)
	if render_snapshot == null:
		return
	_apply_entity_snapshots(
		players,
		render_snapshot.players,
		func(player_snapshot): return player_snapshot.player_id,
		func(player_id):
			var player = PlayerClient.instantiate()
			player.player_name = str(player_names.get(player_id, player_id))
			player_container.add_child(player)
			return player
	)
	
	_apply_entity_snapshots(
		bullets,
		render_snapshot.bullets,
		func(bullet_snapshot): return bullet_snapshot.bullet_id,
		func(bullet_id):
			var bullet = BulletClient.instantiate()
			bullet_container.add_child(bullet)
			return bullet
	)


func _build_interpolated_snapshot(render_tick: float) -> Snapshot:
	var older: Snapshot = null
	var newer: Snapshot = null
	for snapshot in snapshots:
		if snapshot == null:
			continue
		if snapshot.tick <= render_tick:
			if older == null or snapshot.tick > older.tick:
				older = snapshot
		if snapshot.tick >= render_tick:
			if newer == null or snapshot.tick < newer.tick:
				newer = snapshot
	if older == null and newer == null:
		return null
	if older == null:
		return newer
	if newer == null:
		return older
	if older.tick == newer.tick:
		return newer
	var alpha := clampf((render_tick - older.tick) / float(newer.tick - older.tick), 0.0, 1.0)
	return _interpolate_snapshots(older, newer, alpha)


func _interpolate_snapshots(older: Snapshot, newer: Snapshot, alpha: float) -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.tick = int(round(lerpf(float(older.tick), float(newer.tick), alpha)))
	snapshot.players = []
	snapshot.bullets = []
	
	var older_players := _index_player_snapshots(older.players)
	for newer_player in newer.players:
		if older_players.has(newer_player.player_id):
			snapshot.players.append(_interpolate_player_snapshot(older_players[newer_player.player_id], newer_player, alpha))
		else:
			snapshot.players.append(newer_player)
	
	var older_bullets := _index_bullet_snapshots(older.bullets)
	for newer_bullet in newer.bullets:
		if older_bullets.has(newer_bullet.bullet_id):
			snapshot.bullets.append(_interpolate_bullet_snapshot(older_bullets[newer_bullet.bullet_id], newer_bullet, alpha))
		else:
			snapshot.bullets.append(newer_bullet)
	return snapshot


func _index_player_snapshots(player_snapshots: Array[PlayerSnapshot]) -> Dictionary[String, PlayerSnapshot]:
	var indexed: Dictionary[String, PlayerSnapshot] = {}
	for player_snapshot in player_snapshots:
		indexed[player_snapshot.player_id] = player_snapshot
	return indexed


func _index_bullet_snapshots(bullet_snapshots: Array[BulletSnapshot]) -> Dictionary[String, BulletSnapshot]:
	var indexed: Dictionary[String, BulletSnapshot] = {}
	for bullet_snapshot in bullet_snapshots:
		indexed[bullet_snapshot.bullet_id] = bullet_snapshot
	return indexed


func _interpolate_player_snapshot(older: PlayerSnapshot, newer: PlayerSnapshot, alpha: float) -> PlayerSnapshot:
	var snapshot := PlayerSnapshot.new()
	snapshot.player_id = newer.player_id
	snapshot.position = older.position.lerp(newer.position, alpha)
	snapshot.velocity = newer.velocity
	snapshot.health = newer.health
	snapshot.hearts = newer.hearts
	snapshot.facing = newer.facing
	snapshot.is_on_floor = newer.is_on_floor
	snapshot.current_weapon = newer.current_weapon
	snapshot.attacking = newer.attacking
	snapshot.armour_id = newer.armour_id
	snapshot.weapon_ids = newer.weapon_ids
	snapshot.weapon_aim_directions = newer.weapon_aim_directions
	snapshot.weapon_ammunitions = newer.weapon_ammunitions
	snapshot.last_hit = newer.last_hit
	return snapshot


func _interpolate_bullet_snapshot(older: BulletSnapshot, newer: BulletSnapshot, alpha: float) -> BulletSnapshot:
	var snapshot := BulletSnapshot.new()
	snapshot.bullet_id = newer.bullet_id
	snapshot.position = older.position.lerp(newer.position, alpha)
	snapshot.speed = newer.speed
	snapshot.direction = newer.direction
	return snapshot


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
		var id: String = get_id.call(entity_snapshot)
		entities[id].apply_snapshot(entity_snapshot)
