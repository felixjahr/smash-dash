extends Control
class_name VirtualJoystick

enum Joystick_mode {
	FIXED,
	DYNAMIC,
	FOLLOWING,
}

enum Visibility_mode {
	ALWAYS,
	TOUCHSCREEN_ONLY,
	WHEN_TOUCHED,
}

const PRESSED_COLOR := Color.GRAY
const DEADZONE_SIZE: float = 10
const CLAMPZONE_SIZE: float = 75

@export var joystick_mode := Joystick_mode.FIXED
@export var visibility_mode := Visibility_mode.ALWAYS

var is_active := false
var output := Vector2.ZERO

var touch_index : int = -1

@onready var base := $Base
@onready var tip := $Base/Tip

@onready var base_default_position: Vector2 = base.position
@onready var tip_default_position: Vector2 = tip.position

@onready var default_color: Color = tip.modulate


func _ready() -> void:
	if not DisplayServer.is_touchscreen_available() and visibility_mode == Visibility_mode.TOUCHSCREEN_ONLY :
		hide()
	if visibility_mode == Visibility_mode.WHEN_TOUCHED:
		hide()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_joystick_area(event.position) and touch_index == -1:
				if joystick_mode == Joystick_mode.DYNAMIC or joystick_mode == Joystick_mode.FOLLOWING or (joystick_mode == Joystick_mode.FIXED and _is_point_inside_base(event.position)):
					if joystick_mode == Joystick_mode.DYNAMIC or joystick_mode == Joystick_mode.FOLLOWING:
						_move_base(event.position)
					if visibility_mode == Visibility_mode.WHEN_TOUCHED:
						show()
					touch_index = event.index
					tip.modulate = PRESSED_COLOR
					is_active = true
					_update_joystick(event.position)
					get_viewport().set_input_as_handled()
		elif event.index == touch_index:
			_reset()
			if visibility_mode == Visibility_mode.WHEN_TOUCHED:
				hide()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()


func _move_base(new_position: Vector2) -> void:
	base.global_position = new_position - base.pivot_offset * get_global_transform_with_canvas().get_scale()


func _move_tip(new_position: Vector2) -> void:
	tip.global_position = new_position - tip.pivot_offset * base.get_global_transform_with_canvas().get_scale()


func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= global_position.x and point.x <= global_position.x + (size.x * get_global_transform_with_canvas().get_scale().x)
	var y: bool = point.y >= global_position.y and point.y <= global_position.y + (size.y * get_global_transform_with_canvas().get_scale().y)
	return x and y


func _get_base_radius() -> Vector2:
	return base.size * base.get_global_transform_with_canvas().get_scale() / 2


func _is_point_inside_base(point: Vector2) -> bool:
	var base_radius = _get_base_radius()
	var center : Vector2 = base.global_position + base_radius
	var vector : Vector2 = point - center
	if vector.length_squared() <= base_radius.x * base_radius.x:
		return true
	else:
		return false


func _update_joystick(touch_position: Vector2) -> void:
	var base_radius = _get_base_radius()
	var center : Vector2 = base.global_position + base_radius
	var vector : Vector2 = touch_position - center
	vector = vector.limit_length(CLAMPZONE_SIZE)
	
	if joystick_mode == Joystick_mode.FOLLOWING and touch_position.distance_to(center) > CLAMPZONE_SIZE:
		_move_base(touch_position - vector)
	
	_move_tip(center + vector)
	
	if vector.length_squared() > DEADZONE_SIZE * DEADZONE_SIZE:
		output = (vector - (vector.normalized() * DEADZONE_SIZE)) / (CLAMPZONE_SIZE - DEADZONE_SIZE)
	else:
		output = Vector2.ZERO


func _reset():
	is_active = false
	output = Vector2.ZERO
	touch_index = -1
	tip.modulate = default_color
	base.position = base_default_position
	tip.position = tip_default_position
