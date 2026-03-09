extends CharacterBody2D

const ARMOUR := {
	"light_armour" : preload("res://armour/light_armour/light_armour.tres"),
	"heavy_armour" : preload("res://armour/heavy_armour/heavy_armour.tres"),
}

const WEAPONS := {
	"gun" : preload("res://weapons/ranged/gun/gun.tres"),
	"sword" : preload("res://weapons/melee/sword/sword.tres"),
}

const SPEED := 500.0
const ACCELERATION := 1500.0
const FRICTION := 1200.0
const GRAVITY := 1500.0
const JUMP_FORCE := -1200.0

var health := 100
var facing := 1
var current_weapon := 0
var attacking := false
var armour_id := "light_armour"
var weapon_ids: Array[String] = ["gun", "sword"]
var weapon_aim_directions: Array[Vector2]
var weapon_ammunitions: Array[int]
var last_hit := -1

@onready var pivot := $Pivot
@onready var hitbox_collision_shape := $Pivot/Hitbox/CollisionShape2D


func _ready() -> void:
	weapon_ammunitions = []
	for weapon_id in weapon_ids:
		weapon_ammunitions.append(WEAPONS[weapon_id].max_ammunition)
	hitbox_collision_shape.set_deferred("disabled", true)


func tick(delta: float, input: PlayerInput) -> void:
	if input.direction != 0:
		velocity.x = move_toward(velocity.x, input.direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif input.jumping:
		velocity.y = JUMP_FORCE
	
	current_weapon = input.current_weapon
	var weapon: Weapon = WEAPONS[weapon_ids[current_weapon]]
	
	if not attacking:
		if input.attacking and weapon_ammunitions[current_weapon] > 0:
			weapon_ammunitions[current_weapon] -= 1
			
			var weapon_aim_direction := weapon_aim_directions[current_weapon].normalized()
			
			attacking = true
			
			if weapon is Ranged:
				var offset: Vector2 = weapon.bullet_offset
				offset.y *= facing
				var bullet_position: Vector2 = pivot.global_position + offset.rotated(weapon_aim_direction.angle())
				get_parent().get_parent().spawn_bullet(
					bullet_position,
					weapon.bullet_speed,
					weapon.bullet_damage,
					weapon.self_hit,
					weapon_aim_direction,
					int(name),
				)
			
			elif weapon is Melee:
				pivot.rotation = weapon_aim_direction.angle()
				hitbox_collision_shape.set_deferred("disabled", false)
			
			await get_tree().create_timer(weapon.attack_duration).timeout
			
			if weapon is Melee:
				hitbox_collision_shape.set_deferred("disabled", true)
			
			attacking = false
			
			if weapon_ammunitions[current_weapon] == weapon.max_ammunition - 1:
				get_tree().create_timer(weapon.reload_time).timeout.connect(_on_reload_timeout.bind(current_weapon))
		
		else:
			if weapon.moonwalk and not input.weapon_aim_directions[current_weapon] == Vector2.ZERO:
				if input.weapon_aim_directions[current_weapon].x > 0:
					facing = 1
				else:
					facing = -1
			else:
				if velocity.x > 0:
					facing = 1
				elif velocity.x < 0:
					facing = -1
		
	weapon_aim_directions = input.weapon_aim_directions
	
	move_and_slide()


func apply_knockback(position: Vector2, knockback: float) -> void:
	velocity = position.direction_to(global_position) * knockback


func apply_hit(damage: int) -> void:
	health -= damage
	last_hit = get_parent().get_parent().tick
	if health <= 0:
		pass # DIE


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not attacking:
		return
	var weapon: Weapon = WEAPONS[weapon_ids[current_weapon]]
	if not weapon.self_hit and area.get_parent() == self:
		return
	area.get_parent().apply_hit(weapon.damage)
	area.get_parent().apply_knockback(pivot.global_position, weapon.knockback)


func _on_reload_timeout(weapon_idx: int) -> void:
	var weapon = WEAPONS[weapon_ids[weapon_idx]]
	if weapon_ammunitions[weapon_idx] < weapon.max_ammunition:
		weapon_ammunitions[weapon_idx] += 1
	if weapon_ammunitions[weapon_idx] < weapon.max_ammunition:
		get_tree().create_timer(weapon.reload_time).timeout.connect(_on_reload_timeout.bind(weapon_idx))
