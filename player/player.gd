class_name Player
extends CharacterBody2D

const DEFAULT_INPUT = {
	"direction" : 0,
	"jump_pressed" : false,
}

const SPEED := 500.0
const ACCELERATION := 1500.0
const FRICTION := 1200.0
const GRAVITY := 1500.0
const JUMP_FORCE := -1200.0
const KNOCKBACK_DECAY := 10.0

var jumping := false
var health := 100

@onready var sprite := $Sprite
@onready var hurtbox := $Hurtbox
@onready var health_bar := $HealthBar
@onready var animation_player := $AnimationPlayer
@onready var effect_player := $EffectPlayer


func _ready() -> void:
	if !OS.has_feature("match"):
		collision_mask = 0
		hurtbox.collision_layer = 0


# Apply snapshot on client
func apply_snapshot(player: Dictionary, own: bool) -> void:
	global_position = player["global_position"]
	velocity = player["velocity"]
	jumping = player["jumping"]
	
	if health > player["health"]:
		effect_player.play("hit")
	health = player["health"]
	health_bar.value = player["health"]
	
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


# Get input for server
static func get_input() -> Dictionary:
	return {
		"direction" : int(Input.get_axis("move_left", "move_right")),
		"jump_pressed" : Input.is_action_pressed("jump"),
	}


func apply_knockback(position: Vector2, knockback: float):
	velocity = position.direction_to(global_position) * knockback


func apply_damage(damage: int):
	health -= damage
	if health <= 0:
		pass
