extends Control

var output_0 := Vector2.ZERO
var output_1 := Vector2.ZERO

var current_weapon := 0
var attacking := false
var weapon_aim_directions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]

@onready var aim_joystick_0 := $AimJoystick0
@onready var aim_joystick_1 := $AimJoystick1


func update() -> void:
	attacking = false
	
	if not aim_joystick_0.output == weapon_aim_directions[0]:
		current_weapon = 0
		if aim_joystick_0.output == Vector2.ZERO:
			attacking = true
	elif not aim_joystick_1.output == weapon_aim_directions[1]:
		current_weapon = 1
		if aim_joystick_1.output == Vector2.ZERO:
			attacking = true
	
	weapon_aim_directions = [aim_joystick_0.output, aim_joystick_1.output]
