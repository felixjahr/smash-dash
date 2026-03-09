extends Node

const MAX_INPUT_LOOKBACK := 5
const SNAPSHOT_FREQUENCY := 3
const INPUT_BUFFER_SIZE := 128

const MAPS = {
	"forest" : preload("res://maps/forest/forest.tscn"),
	"mountains" : preload("res://maps/mountains/mountains.tscn"),
}

const PlayerModel := preload("res://player/player_model.tscn")
const BulletModel := preload("res://weapons/ranged/bullet_model.tscn")

var tick: int = 0
var map_id: String = "mountains"

var bullet_counter := 0

var players := {}
var bullets := {}

var inputs := {}

@onready var net := $"../Net"
@onready var map_container := $MapContainer
@onready var player_container := $PlayerContainer
@onready var bullet_container := $BulletContainer


func start_match() -> void:
	var new_map = MAPS[map_id].instantiate()
	map_container.add_child(new_map)
	net.start_match()


func _physics_process(delta: float) -> void:
	tick += 1
	
	# Apply input on server
	for pid in players.keys():
		var player_inputs = inputs[pid]
		var input := PlayerInput.new()
		for i in MAX_INPUT_LOOKBACK:
			var wanted_tick := tick - i
			var buffered_input = player_inputs[wanted_tick % INPUT_BUFFER_SIZE]
			if not buffered_input or buffered_input.tick != wanted_tick:
				continue
			input = buffered_input
			break
		players[pid].tick(delta, input)
	
	for bullet in bullets.values():
		bullet.tick(delta)
	
	# Send snapshot for client
	if tick % SNAPSHOT_FREQUENCY == 0:
		var snapshot := Snapshot.new()
		snapshot.tick = tick
		for pid in players.keys():
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
			snapshot.players.append(player_snapshot)
		for bullet_id in bullets.keys():
			var bullet: Node2D = bullets[bullet_id]
			var bullet_snapshot := BulletSnapshot.new()
			bullet_snapshot.bullet_id = bullet_id
			bullet_snapshot.position = bullet.global_position
			bullet_snapshot.speed = bullet.speed
			bullet_snapshot.direction = bullet.direction
			snapshot.bullets.append(bullet_snapshot)
		net.send_snapshot(snapshot)


func spawn_bullet(position: Vector2, speed: int, damage: int, self_hit: bool, direction: Vector2, pid: int) -> void:
	var new_bullet := BulletModel.instantiate()
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


func _on_net_input_received(pid: int, input: PlayerInput) -> void:
	if not inputs.has(pid):
		return
	inputs[pid][input.tick % INPUT_BUFFER_SIZE] = input


func _on_net_peer_connected(pid: int) -> void:
	var new_player := PlayerModel.instantiate()
	new_player.name = str(pid)
	player_container.add_child(new_player)
	players[pid] = new_player
	var input_buffer: Array[PlayerInput] = []
	input_buffer.resize(INPUT_BUFFER_SIZE)
	inputs[pid] = input_buffer
	
	var init := Init.new()
	init.tick = tick
	init.map_id = map_id
	net.send_init(pid, init)


func _on_net_peer_disconnected(pid: int) -> void:
	players[pid].queue_free()
	players.erase(pid)
	inputs.erase(pid)
