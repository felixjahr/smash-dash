extends Node2D

var player: CharacterBody2D

@onready var marker := $Marker2D


func animate_aim(aim_direction: Vector2) -> void:
	if not aim_direction == Vector2.ZERO:
		player.right_shoulder.look_at(player.right_shoulder.global_position + aim_direction)
		player.right_shoulder.rotate(PI/6)
		_set_arm_animations(false)
		player.right_upper_arm.position = Vector2(27.0, 0.0)
		player.right_upper_arm.rotation = 0
		player.right_lower_arm.position = player.right_upper_arm.position + Vector2(40.0, -11.0)
		player.right_lower_arm.rotation = -PI/6
	else:
		_set_arm_animations(true)


func animate_shoot_event(shoot: Dictionary) -> void:
	var new_bullet = player.BULLETS["gun"].instantiate()
	player.get_parent().add_child(new_bullet)
	new_bullet.setup(shoot["bullet_position"], shoot["bullet_direction"], 10)


func simulate_shoot(aim_direction) -> Dictionary:
	var new_bullet = player.BULLETS["gun"].instantiate()
	player.get_parent().add_child(new_bullet)
	
	# Caclulate bullet position
	player.right_shoulder.look_at(player.right_shoulder.global_position + aim_direction)
	player.right_shoulder.rotate(PI/6)
	player.right_upper_arm.position = Vector2(27.0, 0.0)
	player.right_upper_arm.rotation = 0
	player.right_lower_arm.position = player.right_upper_arm.position + Vector2(40.0, -11.0)
	player.right_lower_arm.rotation = -PI/6
	
	new_bullet.setup(marker.global_position, aim_direction, 10)
	
	return {
		"bullet_position" : marker.global_position,
		"bullet_direction" : aim_direction,
	}


func _set_arm_animations(enabled: bool) -> void:
	var target_tracks = [
		"Sprite/RightShoulder:rotation",
		"Sprite/RightShoulder/RightUpperArm:position",
		"Sprite/RightShoulder/RightLowerArm:position",
		"Sprite/RightShoulder/RightUpperArm:rotation",
		"Sprite/RightShoulder/RightLowerArm:rotation"
	]
	for anim_name in player.animation_player.get_animation_list():
		var anim = player.animation_player.get_animation(anim_name)
		for track_path in target_tracks:
			var track_idx = anim.find_track(track_path, Animation.TYPE_VALUE)
			if track_idx != -1:
				anim.track_set_enabled(track_idx, enabled)
