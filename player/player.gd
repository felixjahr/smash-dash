extends CharacterBody2D

var speed := 500.0
var acceleration := 1500.0
var friction := 1200.0
var gravity := 1500.0
var jump_force := -1200.0

var jumping := false

@onready var sprite := $Sprite
@onready var animation_player := $AnimationPlayer


func animate(jumping: bool) -> void:
	self.jumping = jumping
	
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


func simulate(input_dir: float, jump_pressed: bool, delta: float) -> void:
	if input_dir != 0:
		velocity.x = move_toward(velocity.x, input_dir * speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	if not is_on_floor():
		velocity.y += gravity * delta
	elif jump_pressed and not jumping:
		velocity.y = jump_force
		jumping = true
	else:
		jumping = false
	
	move_and_slide()
