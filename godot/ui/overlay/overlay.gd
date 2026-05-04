extends Control

var output_0 := Vector2.ZERO
var output_1 := Vector2.ZERO

var current_weapon := 0
var weapon_aim_directions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
var direction := 0.0
var jumping := false

@onready var aim_joystick_0 := $AimJoystick0
@onready var aim_joystick_1 := $AimJoystick1


func poll() -> void:
	if aim_joystick_0.output != weapon_aim_directions[0]:
		current_weapon = 0
	elif aim_joystick_1.output != weapon_aim_directions[1]:
		current_weapon = 1
	weapon_aim_directions = [aim_joystick_0.output, aim_joystick_1.output]
	direction = Input.get_axis("move_left", "move_right")
	jumping = Input.is_action_pressed("jump")
