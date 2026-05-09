extends CharacterBody2D

const SPEED := 500.0
const ACCELERATION := 1500.0
const FRICTION := 1200.0
const GRAVITY := 1500.0
const JUMP_FORCE := -1200.0

var player_id: String
var health := 100
var hearts := 3
var facing := 1
var current_weapon := 0
var attacking := false
var armour_id: String
var weapon_ids: Array[String]
var ability_id: String
var weapon_aim_directions: Array[Vector2] = []
var weapon_ammunitions: Array[int] = []
var last_hit := -1

var reload_times_left: Array[float] = []
var attack_time_left := 0.0
var burst_time_left := 0.0
var burst_weapon: Weapon
var burst_aim_direction: Vector2
var burst_bullet_amount: int

var ability_recharge_time: float

@onready var logic := get_parent().get_parent()
@onready var pivot := $Pivot
@onready var hitbox_collision_shape := $Pivot/Hitbox/CollisionShape2D


func _ready() -> void:
	for weapon_id in weapon_ids:
		weapon_ammunitions.append(Data.WEAPON[weapon_id].max_ammunition)
		weapon_aim_directions.append(Vector2.ZERO)
		reload_times_left.append(0.0)
	ability_recharge_time = Data.ABILITY[ability_id].recharge_time
	hitbox_collision_shape.set_deferred("disabled", true)


func tick(delta: float, input: PlayerInput) -> void:
	_update_reload_times(delta)
	_update_ability_recharge_time(delta)
	_update_attack_time(delta)
	_update_burst_time(delta)
	
	_apply_horizontal_movement(delta, input.direction)
	_apply_vertical_movement(delta, input.jumping)
	
	if input.ability and ability_recharge_time <= 0.0:
		ability_recharge_time = Data.ABILITY[ability_id].recharge_time
		match ability_id:
			"double_jump":
				_ability_double_jump()
			"dash":
				_ability_dash(input.direction)

	if not attacking:
		current_weapon = input.current_weapon
		var weapon := Data.WEAPON[weapon_ids[current_weapon]]

		var previous_aim_direction := weapon_aim_directions[current_weapon]
		var aim_direction := input.weapon_aim_directions[current_weapon]
		weapon_aim_directions = input.weapon_aim_directions
		
		if _should_start_attack(aim_direction, previous_aim_direction):
			_start_attack(weapon, previous_aim_direction)
		else:
			_update_facing(weapon, aim_direction)
	
	move_and_slide()


func apply_knockback(position: Vector2, knockback: float) -> void:
	var knockback_multiplier := Data.ARMOUR[armour_id].knockback_multiplier
	velocity = position.direction_to(global_position) * knockback * knockback_multiplier


func apply_hit(damage: int) -> void:
	var damage_multiplier := Data.ARMOUR[armour_id].damage_multiplier
	health -= damage * damage_multiplier
	last_hit = logic.tick
	if health <= 0:
		_die()


func _die() -> void:
	hearts -= 1
	if hearts <= 0:
		logic.gameover()
		return
	logic.call_deferred("spawn_player", player_id, weapon_ids, armour_id, ability_id, hearts)
	queue_free()


func _update_reload_times(delta: float) -> void:
	for i in reload_times_left.size():
		if reload_times_left[i] <= 0.0:
			continue
		reload_times_left[i] -= delta
		if reload_times_left[i] <= 0.0:
			reload_times_left[i] = 0.0
			var weapon := Data.WEAPON[weapon_ids[i]]
			if weapon_ammunitions[i] < weapon.max_ammunition:
				weapon_ammunitions[i] += 1
				if weapon_ammunitions[i] < weapon.max_ammunition:
					reload_times_left[i] = weapon.reload_time


func _update_ability_recharge_time(delta: float) -> void:
	if ability_recharge_time > 0.0:
		ability_recharge_time -= delta


func _update_attack_time(delta: float) -> void:
	if attack_time_left <= 0.0:
		return
	attack_time_left -= delta
	if attack_time_left <= 0.0:
		attack_time_left = 0.0
		attacking = false
		hitbox_collision_shape.set_deferred("disabled", true)


func _update_burst_time(delta: float) -> void:
	if burst_time_left <= 0.0:
		return
	burst_time_left -= delta
	if burst_time_left <= 0.0:
		burst_time_left = 0.0
		_fire_shot()


func _apply_horizontal_movement(delta: float, direction: float) -> void:
	if direction != 0:
		var speed_multiplier := Data.ARMOUR[armour_id].speed_multiplier
		velocity.x = move_toward(velocity.x, direction * SPEED * speed_multiplier, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)


func _apply_vertical_movement(delta: float, jumping: bool) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif jumping:
		var jump_multiplier := Data.ARMOUR[armour_id].jump_multiplier
		velocity.y = JUMP_FORCE * jump_multiplier


func _should_start_attack(aim_direction: Vector2, previous_aim_direction: Vector2) -> bool:
	return (
		aim_direction == Vector2.ZERO 
		and previous_aim_direction.length_squared() > 0.04 
		and weapon_ammunitions[current_weapon] > 0
	)


func _start_attack(weapon: Weapon, aim_direction: Vector2) -> void:
	weapon_ammunitions[current_weapon] -= 1
	if reload_times_left[current_weapon] <= 0.0:
		reload_times_left[current_weapon] = weapon.reload_time
	
	attacking = true
	
	if weapon is Ranged:
		_start_ranged_attack(weapon, aim_direction, weapon.bullet_amount)
	elif weapon is Melee:
		_start_melee_attack(weapon, aim_direction)


func _start_ranged_attack(weapon: Weapon, aim_direction: Vector2, bullet_amount: int) -> void:
	attack_time_left = weapon.attack_duration * bullet_amount
	burst_weapon = weapon
	burst_aim_direction = aim_direction
	burst_bullet_amount = bullet_amount
	_fire_shot()


func _fire_shot() -> void:
	var offset: Vector2 = burst_weapon.bullet_offset
	offset.y *= facing
	var bullet_position: Vector2 = pivot.global_position + offset.rotated(burst_aim_direction.angle())
	logic.spawn_bullet(
		bullet_position,
		burst_weapon.bullet_speed,
		burst_weapon.bullet_damage,
		burst_weapon.self_hit,
		burst_aim_direction.normalized(),
		player_id,
	)
	burst_bullet_amount -= 1
	if burst_bullet_amount > 0:
		burst_time_left = burst_weapon.attack_duration


func _start_melee_attack(weapon: Weapon, aim_direction: Vector2) -> void:
	attack_time_left = weapon.attack_duration
	pivot.rotation = aim_direction.angle()
	hitbox_collision_shape.shape.size = weapon.hitbox_size
	hitbox_collision_shape.position.x = weapon.hitbox_size.x / 2
	hitbox_collision_shape.set_deferred("disabled", false)


func _update_facing(weapon: Weapon, aim_direction: Vector2) -> void:
	if weapon.moonwalk and aim_direction != Vector2.ZERO:
		if aim_direction.x > 0:
			facing = 1
		else:
			facing = -1
	else:
		if velocity.x > 0:
			facing = 1
		elif velocity.x < 0:
			facing = -1


func _ability_double_jump() -> void:
	var armour_jump_multiplier := Data.ARMOUR[armour_id].jump_multiplier
	var dash_jump_multiplier: float = Data.ABILITY[ability_id].jump_multiplier
	velocity.y = JUMP_FORCE * armour_jump_multiplier * dash_jump_multiplier


func _ability_dash(direction: float) -> void:
	var dash_direction: int
	if direction != 0:
		dash_direction = signf(direction)
	else:
		dash_direction = facing
	var distance: int = Data.ABILITY[ability_id].distance
	move_and_collide(Vector2(dash_direction, 0) * distance)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not attacking:
		return
	var weapon := Data.WEAPON[weapon_ids[current_weapon]]
	if not weapon.self_hit and area.get_parent() == self:
		return
	area.get_parent().apply_hit(weapon.damage)
	area.get_parent().apply_knockback(pivot.global_position, weapon.knockback)


func _on_arena_area_exited(area: Area2D) -> void:
	_die()
