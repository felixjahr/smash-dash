extends CharacterBody2D

const BULLETS = {
	"gun" : preload("res://weapons/gun/gun_bullet.tscn"),
}

const WEAPONS = {
	"gun" : preload("res://weapons/gun/gun.tscn"),
}

const SPEED := 500.0
const ACCELERATION := 1500.0
const FRICTION := 1200.0
const GRAVITY := 1500.0
const JUMP_FORCE := -1200.0
const KNOCKBACK_DECAY := 10.0

var jumping := false
var aim_direction_1 := Vector2.ZERO
var aim_direction_2 := Vector2.ZERO
var health := 100
var weapon_1_id := "gun"
var weapon_2_id := "gun"

var camera: Camera2D

var weapon_1
var weapon_2

@onready var sprite := $Sprite
@onready var hurtbox := $Hurtbox
@onready var health_bar := $HealthBar
@onready var animation_player := $AnimationPlayer
@onready var effect_player := $EffectPlayer
@onready var right_shoulder := $Sprite/RightShoulder
@onready var right_upper_arm := $Sprite/RightShoulder/RightUpperArm
@onready var right_lower_arm := $Sprite/RightShoulder/RightLowerArm


func _ready() -> void:
	if !OS.has_feature("match"):
		collision_mask = 0
		hurtbox.collision_layer = 0
		var lib: AnimationLibrary = animation_player.get_animation_library("").duplicate(true)
		animation_player.remove_animation_library("")
		animation_player.add_animation_library("", lib)
	var new_weapon_1 = WEAPONS[weapon_1_id].instantiate()
	right_lower_arm.add_child(new_weapon_1)
	new_weapon_1.player = self
	weapon_1 = new_weapon_1
	var new_weapon_2 = WEAPONS[weapon_2_id].instantiate()
	right_lower_arm.add_child(new_weapon_2)
	new_weapon_2.player = self
	new_weapon_2.scale = Vector2(0.5, 0.5) # Test
	new_weapon_2.hide()
	weapon_2 = new_weapon_2


func animate_snapshot(player_snapshot: Dictionary) -> void:
	global_position = player_snapshot["global_position"]
	velocity = player_snapshot["velocity"]
	
	health_bar.value = player_snapshot["health"]
	
	if not player_snapshot["aim_direction_1"] == Vector2.ZERO:
		weapon_1.show()
		weapon_2.hide()
	elif not player_snapshot["aim_direction_2"] == Vector2.ZERO:
		weapon_1.hide()
		weapon_2.show()
	if weapon_1.visible:
		weapon_1.animate_aim(player_snapshot["aim_direction_1"])
	elif weapon_2.visible:
		weapon_2.animate_aim(player_snapshot["aim_direction_2"])
	
	if camera:
		camera.global_position = global_position
	
	if velocity.x > 0:
		sprite.scale.x = 1
	elif velocity.x < 0:
		sprite.scale.x = -1
	
	if player_snapshot["jumping"]:
		animation_player.play("jump")
	elif velocity.x != 0:
		animation_player.play("move")
	else:
		animation_player.play("idle")
	
	if velocity.x > 0:
		sprite.scale.x = 1
	elif velocity.x < 0:
		sprite.scale.x = -1


func animate_shoot_event(weapon_number: int, shoot: Dictionary) -> void:
	get("weapon_" + str(weapon_number)).animate_shoot_event(shoot)


func animate_melee_event() -> void:
	pass


func animate_ability_event() -> void:
	pass


func animate_hit_event() -> void:
	effect_player.play("hit")


func simulate_input(input: Dictionary, delta: float) -> void:
	if aim_direction_1.length() > 0.2 and input["aim_direction_1"] == Vector2.ZERO:
		var shoot: Dictionary = weapon_1.simulate_shoot(aim_direction_1)
		get_parent().send_shoot_event(int(name), 1, shoot)
	aim_direction_1 = input["aim_direction_1"]
	if aim_direction_2.length() > 0.2 and input["aim_direction_2"] == Vector2.ZERO:
		var shoot: Dictionary = weapon_2.simulate_shoot(aim_direction_2)
		get_parent().send_shoot_event(int(name), 2, shoot)
	aim_direction_2 = input["aim_direction_2"]
	
	var direction = input["direction"]
	var jump_pressed = input["jump_pressed"]
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif jump_pressed and not jumping:
		velocity.y = JUMP_FORCE
		jumping = true
	else:
		jumping = false
	
	move_and_slide()


func simulate_knockback(position: Vector2, knockback: float) -> void:
	velocity = position.direction_to(global_position) * knockback


func simulate_hit(damage: int) -> void:
	health -= damage
	get_parent().send_hit_event(int(name))
	if health <= 0:
		pass
