extends Node

const TICK_RATE := 60.0
const INPUT_LEAD := 5
const SNAPSHOT_BUFFER_SIZE := 128
const INPUT_BUFFER_SIZE := 128

const MAPS = {
	"forest" : preload("res://maps/forest/forest.tscn"),
}

const PlayerView := preload("res://player/player_view.tscn")
const BulletView := preload("res://weapons/ranged/bullet_view.tscn")

var estimated_server_tick: float
var last_snapshot_tick := -1

var local_pid := -1
var players := {}
var bullets := {}

var snapshots: Array[Snapshot]
var inputs: Array[PlayerInput]

var overlay: Control

@onready var net := $"../Net"
@onready var map_container := $MapContainer
@onready var remote_player_container := $RemotePlayerContainer
@onready var local_player_container := $LocalPlayerContainer
@onready var bullet_container := $BulletContainer


func _ready() -> void:
	snapshots.resize(SNAPSHOT_BUFFER_SIZE)
	inputs.resize(INPUT_BUFFER_SIZE)
	set_physics_process(false)


func start_match() -> void:
	net.start_match()


func _physics_process(delta: float) -> void:
	# Update tick estimate
	estimated_server_tick += delta * TICK_RATE
	
	# Send input for server	
	overlay.update()
	var input := PlayerInput.new()
	input.tick = int(estimated_server_tick) + INPUT_LEAD
	input.direction = Input.get_axis("move_left", "move_right")
	input.jumping = Input.is_action_pressed("jump")
	input.current_weapon = overlay.current_weapon
	input.attacking = overlay.attacking
	input.weapon_aim_directions = overlay.weapon_aim_directions
	inputs[input.tick % INPUT_BUFFER_SIZE] = input
	net.send_input(input)


func _on_net_snapshot_received(snapshot: Snapshot) -> void:
	# Save snapshot
	snapshots[snapshot.tick % SNAPSHOT_BUFFER_SIZE] = snapshot
	
	# Check if snapshot arrived out of order
	if snapshot.tick < last_snapshot_tick:
		return
	last_snapshot_tick = snapshot.tick
	estimated_server_tick = snapshot.tick
	
	# Apply player snapshots
	var snapshot_pids := snapshot.players.map(func(player): return player.pid)
	for pid in players.keys():
		if pid == local_pid:
			continue
		if not snapshot_pids.has(pid):
			players[pid].queue_free()
			players.erase(pid)
	for pid in snapshot_pids:
		if pid == local_pid:
			continue
		if not players.has(pid):
			var new_player = PlayerView.instantiate()
			new_player.name = str(pid)
			remote_player_container.add_child(new_player)
			players[pid] = new_player
	
	for player_snapshot in snapshot.players:
		players[player_snapshot.pid].apply_snapshot(player_snapshot)
	
	# Apply bullet snapshots
	var snapshot_bullet_ids := snapshot.bullets.map(func(bullet) : return bullet.bullet_id)
	for bullet_id in bullets.keys():
		if not snapshot_bullet_ids.has(bullet_id):
			bullets[bullet_id].queue_free()
			bullets.erase(bullet_id)
	for bullet_id in snapshot_bullet_ids:
		if not bullets.has(bullet_id):
			var new_bullet = BulletView.instantiate()
			new_bullet.name = str(bullet_id)
			bullet_container.add_child(new_bullet)
			bullets[bullet_id] = new_bullet
	
	for bullet_snapshot in snapshot.bullets:
		bullets[bullet_snapshot.bullet_id].apply_snapshot(bullet_snapshot)


func _on_net_init_received(init: Init) -> void:
	# Add map
	var new_map = MAPS[init.map_id].instantiate()
	map_container.add_child(new_map)
	
	# Add local player
	local_pid = multiplayer.get_unique_id()
	var new_player = PlayerView.instantiate()
	new_player.name = str(local_pid)
	new_player.local = true
	new_player.camera = new_map.camera
	local_player_container.add_child(new_player)
	players[local_pid] = new_player
	
	# Start sending inputs
	estimated_server_tick = init.tick
	set_physics_process(true)
