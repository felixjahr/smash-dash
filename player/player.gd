class_name Player
extends CharacterBody2D

const DEFAULT_INPUT = {
	"direction" : 0,
	"jump_pressed" : false,
}

var speed := 500.0
var acceleration := 1500.0
var friction := 1200.0
var gravity := 1500.0
var jump_force := -1200.0

var jumping := false
var health := 100

@onready var sprite := $Sprite
@onready var hurtbox := $Hurtbox
@onready var animation_player := $AnimationPlayer
@onready var effect_player := $EffectPlayer


func _ready() -> void:
	if !OS.has_feature("match"):
		collision_mask = 0
		hurtbox.collision_mask = 0
		hurtbox.collision_layer = 0


# Apply snapshot on client
func apply_snapshot(player: Dictionary, own: bool) -> void:
	global_position = player["global_position"]
	velocity = player["velocity"]
	jumping = player["jumping"]
	
	if health > player["health"]:
		effect_player.play("hit")
	health = player["health"]
	
	if own:
		get_parent().get_node("Forest/Camera2D").global_position = global_position
	
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


# Get snapshot for client
func get_snapshot() -> Dictionary:
	return {
		"global_position" : global_position,
		"velocity" : velocity,
		"jumping" : jumping,
		"health" : health,
	}


# Apply input on server
func apply_input(input: Dictionary, delta: float) -> void:
	var direction = input["direction"]
	var jump_pressed = input["jump_pressed"]
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * speed, acceleration * delta)
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


# Get input for server
static func get_input() -> Dictionary:
	return {
		"direction" : int(Input.get_axis("move_left", "move_right")),
		"jump_pressed" : Input.is_action_pressed("jump"),
	}


func _on_hurtbox_area_entered(area: Area2D) -> void:
	health -= 10
