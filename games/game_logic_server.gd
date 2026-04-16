extends Node

const MAX_INPUT_LOOKBACK := 5
const SNAPSHOT_FREQUENCY := 3
const INPUT_BUFFER_SIZE := 128

const PlayerServer := preload("res://player/player_server.tscn")
const BulletServer := preload("res://bullet/bullet_server.tscn")

var tick := 0

var bullet_counter := 0

var players: Dictionary[int, CharacterBody2D] = {}
var bullets: Dictionary[int, Node2D] = {}

var inputs: Dictionary[int, Array] = {}

@onready var map_container := $MapContainer
@onready var player_container := $PlayerContainer
@onready var bullet_container := $BulletContainer


func _physics_process(delta: float) -> void:
	tick += 1
	
	_tick_players(delta)
	_tick_bullets(delta)
	
	if tick % SNAPSHOT_FREQUENCY == 0:
		get_parent().game_net.send_snapshot(_build_snapshot())


func spawn_map(map_id: String) -> void:
	var new_map := Data.MAPS[map_id].instantiate()
	map_container.add_child(new_map)


func spawn_player(pid: int, weapon_ids: Array[String], armour_id: String) -> void:
	var new_player := PlayerServer.instantiate()
	new_player.name = str(pid)
	new_player.weapon_ids = weapon_ids
	new_player.armour_id = armour_id
	player_container.add_child(new_player)
	players[pid] = new_player
	var input_buffer: Array[PlayerInput] = []
	input_buffer.resize(INPUT_BUFFER_SIZE)
	inputs[pid] = input_buffer


func spawn_bullet(position: Vector2, speed: int, damage: int, self_hit: bool, direction: Vector2, pid: int) -> void:
	var new_bullet := BulletServer.instantiate()
	new_bullet.name = str(bullet_counter)
	new_bullet.global_position = position
	new_bullet.speed = speed
	new_bullet.damage = damage
	new_bullet.self_hit = self_hit
	new_bullet.direction = direction
	new_bullet.pid = pid
	bullet_container.add_child(new_bullet)
	bullets[bullet_counter] = new_bullet
	bullet_counter += 1


func despawn_bullet(bullet_id: int) -> void:
	if not bullets.has(bullet_id):
		return
	bullets[bullet_id].queue_free()
	bullets.erase(bullet_id)


func _tick_players(delta: float) -> void:
	for pid in players.keys():
		var player := players[pid]
		var input := _get_latest_input(pid)
		player.tick(delta, input)


func _get_latest_input(pid: int) -> PlayerInput:
	var player_inputs := inputs[pid]
	var latest_input := PlayerInput.new()
	for i in MAX_INPUT_LOOKBACK:
		var wanted_tick := tick - i
		var buffered_input = player_inputs[wanted_tick % INPUT_BUFFER_SIZE]
		if not buffered_input:
			continue
		if buffered_input.tick != wanted_tick:
			continue
		latest_input = buffered_input
		break
	return latest_input


func _tick_bullets(delta: float) -> void:
	for bullet in bullets.values():
		bullet.tick(delta)


func _build_snapshot() -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.tick = tick
	for pid in players.keys():
		snapshot.players.append(_build_player_snapshot(pid))
	for bullet_id in bullets.keys():
		snapshot.bullets.append(_build_bullet_snapshot(bullet_id))
	return snapshot


func _build_player_snapshot(pid: int) -> PlayerSnapshot:
	var player: CharacterBody2D = players[pid]
	var player_snapshot := PlayerSnapshot.new()
	player_snapshot.pid = pid
	player_snapshot.position = player.global_position
	player_snapshot.velocity = player.velocity
	player_snapshot.health = player.health
	player_snapshot.facing = player.facing
	player_snapshot.is_on_floor = player.is_on_floor()
	player_snapshot.current_weapon = player.current_weapon
	player_snapshot.attacking = player.attacking
	player_snapshot.armour_id = player.armour_id
	player_snapshot.weapon_ids = player.weapon_ids
	player_snapshot.weapon_aim_directions = player.weapon_aim_directions
	player_snapshot.weapon_ammunitions = player.weapon_ammunitions
	player_snapshot.last_hit = player.last_hit
	return player_snapshot


func _build_bullet_snapshot(bullet_id: int) -> BulletSnapshot:
	var bullet: Node2D = bullets[bullet_id]
	var bullet_snapshot := BulletSnapshot.new()
	bullet_snapshot.bullet_id = bullet_id
	bullet_snapshot.position = bullet.global_position
	bullet_snapshot.speed = bullet.speed
	bullet_snapshot.direction = bullet.direction
	return bullet_snapshot


func _on_net_input_received(pid: int, input: PlayerInput) -> void:
	if not inputs.has(pid):
		return
	inputs[pid][input.tick % INPUT_BUFFER_SIZE] = input
