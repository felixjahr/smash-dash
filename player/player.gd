extends CharacterBody2D

@export var speed := 500.0
@export var acceleration := 1500.0
@export var friction := 1200.0
@export var gravity := 1500.0
@export var jump_force := -1200.0

@export var facing := 1
var jumping := false

@onready var sprite := $Sprite
@onready var animation_player := $AnimationPlayer


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
