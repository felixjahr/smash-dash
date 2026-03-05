class_name Player
extends CharacterBody2D

const DEFAULT_INPUT = {
	"direction" : 0,
	"jump_pressed" : false,
	"aim_direction" : Vector2.ZERO,
}

const SPEED := 500.0
const ACCELERATION := 1500.0
const FRICTION := 1200.0
const GRAVITY := 1500.0
const JUMP_FORCE := -1200.0
const KNOCKBACK_DECAY := 10.0

#const GunBullet := preload("res://weapons/gun/gun_bullet.tscn")

var jumping := false
var aim_direction := Vector2.ZERO
var health := 100

@onready var sprite := $Sprite
@onready var hurtbox := $Hurtbox
@onready var health_bar := $HealthBar
@onready var animation_player := $AnimationPlayer
@onready var effect_player := $EffectPlayer
@onready var right_shoulder := $Sprite/RightShoulder
@onready var right_upper_arm := $Sprite/RightShoulder/RightUpperArm
@onready var right_lower_arm := $Sprite/RightShoulder/RightLowerArm
@onready var gun := $Sprite/RightShoulder/RightLowerArm/Gun

var aim_joystick: VirtualJoystick
var camera: Camera2D


func _ready() -> void:
	if !OS.has_feature("match"):
		collision_mask = 0
		hurtbox.collision_layer = 0
		if str(multiplayer.get_unique_id()) == name:
			aim_joystick = get_parent().get_parent().get_node("UIContainer/Match/VirtualJoystick")
		var lib: AnimationLibrary = animation_player.get_animation_library("").duplicate(true)
		animation_player.remove_animation_library("")
		animation_player.add_animation_library("", lib)


# Apply snapshot on client
func apply_snapshot(player: Dictionary) -> void:
	global_position = player["global_position"]
	velocity = player["velocity"]
	jumping = player["jumping"]
	aim_direction = player["aim_direction"]
	
	if health > player["health"]:
		effect_player.play("hit")
	health = player["health"]
	health_bar.value = player["health"]
	
	if not aim_direction == Vector2.ZERO:
		right_shoulder.look_at(right_shoulder.global_position + aim_direction)
		right_shoulder.rotate(PI/6)
		
		gun.visible = true
		_set_arm_animations(false)
		right_upper_arm.position = Vector2(27.0, 0.0)
		right_upper_arm.rotation = 0
		right_lower_arm.position = right_upper_arm.position + Vector2(40.0, -11.0)
		right_lower_arm.rotation = -PI/6
	else:
		gun.visible = false
		_set_arm_animations(true)
	
	if camera:
		camera.global_position = global_position
	
	if velocity.x > 0:
		sprite.scale.x = 1
	elif velocity.x < 0:
		sprite.scale.x = -1
	
	if jumping:
		animation_player.play("jump")
	elif velocity.x != 0:
		animation_player.play("move")
	else:
		animation_player.play("idle")
	
	if velocity.x > 0:
		sprite.scale.x = 1
	elif velocity.x < 0:
		sprite.scale.x = -1


# Get input for server
func get_input() -> Dictionary:
	return {
		"direction" : int(Input.get_axis("move_left", "move_right")),
		"jump_pressed" : Input.is_action_pressed("jump"),
		"aim_direction" : aim_joystick.output,
	}


# Apply input on server
func apply_input(input: Dictionary, delta: float) -> void:
	if aim_direction.length() > 0.2 and input["aim_direction"] == Vector2.ZERO:
		print("Piu!")
		#var new_bullet = GunBullet.instantiate()
		#new_bullet.global_position = gun.get_node("Marker2D").global_position
		#new_bullet.direction = aim_direction.normalized()
		#get_parent().add_child(new_bullet)
	aim_direction = input["aim_direction"]
	
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


# Get snapshot for client
func get_snapshot() -> Dictionary:
	return {
		"global_position" : global_position,
		"velocity" : velocity,
		"jumping" : jumping,
		"aim_direction" : aim_direction,
		"health" : health,
	}


func apply_knockback(position: Vector2, knockback: float):
	velocity = position.direction_to(global_position) * knockback


func apply_damage(damage: int):
	health -= damage
	if health <= 0:
		pass


func _set_arm_animations(enabled: bool) -> void:
	var target_tracks = [
		"Sprite/RightShoulder:rotation",
		"Sprite/RightShoulder/RightUpperArm:position",
		"Sprite/RightShoulder/RightLowerArm:position",
		"Sprite/RightShoulder/RightUpperArm:rotation",
		"Sprite/RightShoulder/RightLowerArm:rotation"
	]
	
	for anim_name in animation_player.get_animation_list():
		var anim = animation_player.get_animation(anim_name)
		for track_path in target_tracks:
			var track_idx = anim.find_track(track_path, Animation.TYPE_VALUE)
			if track_idx != -1:
				anim.track_set_enabled(track_idx, enabled)
