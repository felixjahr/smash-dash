extends Control

signal pressed

const TEXTURE = {
	"dash" : preload("res://ui/overlay/ability_button/dash.png"),
	"double_jump" : preload("res://ui/overlay/ability_button/double_jump.png"),
	"invisibility" : preload("res://ui/overlay/ability_button/invisibility.png"),
	"slam_down" : preload("res://ui/overlay/ability_button/slam_down.png"),
}

const TEXTURE_PRESSED = {
	"dash" : preload("res://ui/overlay/ability_button/dash_disabled.png"),
	"double_jump" : preload("res://ui/overlay/ability_button/double_jump_disabled.png"),
	"invisibility" : preload("res://ui/overlay/ability_button/invisibility_disabled.png"),
	"slam_down" : preload("res://ui/overlay/ability_button/slam_down_disabled.png"),
}

const TEXTURE_UNDER = {
	"dash" : preload("res://ui/overlay/ability_button/dash_disabled.png"),
	"double_jump" : preload("res://ui/overlay/ability_button/double_jump_disabled.png"),
	"invisibility" : preload("res://ui/overlay/ability_button/invisibility_disabled.png"),
	"slam_down" : preload("res://ui/overlay/ability_button/slam_down_disabled.png"),
}

var active_touch_index := -1
var disabled := false
var ability_id := ""

@onready var texture := $CanvasGroup/Texture


func handle_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_activate_touch(event.index, event.position)
		else:
			_release_touch(event.index)


func set_ability(ability_id: String) -> void:
	texture.texture_progress = TEXTURE[ability_id]
	texture.texture_under = TEXTURE_UNDER[ability_id]
	self.ability_id = ability_id


func set_texture_value(value: float) -> void:
	texture.value = value
	disabled = value < 100.0


func _activate_touch(touch_index: int, touch_position: Vector2) -> void:
	if disabled or active_touch_index != -1 or not get_global_rect().has_point(touch_position):
		return
	print("handle")
	active_touch_index = touch_index
	#texture.texture_progress = texture_pressed
	pressed.emit()
	get_viewport().set_input_as_handled()


func _release_touch(touch_index: int) -> void:
	if touch_index != active_touch_index:
		return
	_reset_touch()
	get_viewport().set_input_as_handled()


func _reset_touch():
	active_touch_index = -1
	#texture.texture = texture_normal
