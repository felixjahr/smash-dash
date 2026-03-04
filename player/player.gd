extends CharacterBody2D

@export var speed := 500.0
@export var acceleration := 1500.0
@export var friction := 1200.0
@export var gravity := 1500.0
@export var jump_force := -1200.0

@export var facing := 1

@export var aim_joystick : VirtualJoystick

var jumping := false

var was_aiming := false
var last_aim_direction := Vector2.ZERO


@onready var sprite := $Sprite
@onready var animation_player := $AnimationPlayer

@onready var right_shoulder := $Sprite/RightShoulder
@onready var right_upper_arm := $Sprite/RightShoulder/RightUpperArm
@onready var right_lower_arm := $Sprite/RightShoulder/RightLowerArm
@onready var gun := $Sprite/RightShoulder/RightLowerArm/Gun


# Enables right arm adjustments
func set_right_arm_adjustments_enabled(enabled: bool) -> void:
	var anim_names = ["idle", "move", "jump"]
	var target_tracks = [
		"Sprite/RightShoulder:rotation",
		"Sprite/RightShoulder/RightUpperArm:position",
		"Sprite/RightShoulder/RightLowerArm:position",
		"Sprite/RightShoulder/RightUpperArm:rotation",
		"Sprite/RightShoulder/RightLowerArm:rotation"
	]
	
	for anim_name in anim_names:
		if animation_player.has_animation(anim_name):
			var anim = animation_player.get_animation(anim_name)
			
			for track_path in target_tracks:
				var track_idx = anim.find_track(track_path, Animation.TYPE_VALUE)
				if track_idx != -1:
					anim.track_set_enabled(track_idx, enabled)


func _physics_process(delta: float) -> void:
	var input_dir = Input.get_axis("move_left", "move_right")
	
	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	if velocity.x > 0:
		facing = 1
	elif velocity.x < 0:
		facing = -1
	sprite.scale.x = facing
	
	


# Handle aiming
	if aim_joystick and aim_joystick.is_pressed:
		was_aiming = true
		last_aim_direction = aim_joystick.output
		
		gun.visible = true
		set_right_arm_adjustments_enabled(false)
		
		#right_shoulder.look_at(right_shoulder.global_position + Vector2.UP)
		right_shoulder.look_at(right_shoulder.global_position + aim_joystick.output)
		
		right_upper_arm.position = Vector2(27.0, 0.0)
		right_upper_arm.rotation = 0
		right_lower_arm.position = right_upper_arm.position + Vector2(40.0, -11.0)
		right_lower_arm.rotation = -PI/6
		
		right_shoulder.rotate(PI/6)

		
	else:
		if was_aiming:
			was_aiming = false
			if last_aim_direction.length() > .2:
				print("Piu!")
		gun.visible = false
		set_right_arm_adjustments_enabled(true)

		
	
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		jumping = true
	else:
		jumping = false
	
	if jumping:
		animation_player.play("jump")
	elif velocity.x != 0:
		animation_player.play("move")
	else:
		animation_player.play("idle")
	
	move_and_slide()
