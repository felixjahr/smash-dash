class_name Ranged
extends Weapon

@export var bullet: PackedScene
@export var bullet_speed := 2000
@export var bullet_damage := 10

@onready var marker := $Marker2D

var bullet_counter := 0


func animate_aim(aim_direction: Vector2) -> void:
	player.right_shoulder.look_at(player.right_shoulder.global_position + aim_direction)
	player.arm_player.play(aim_animation)


func animate_attack_event(attack: Dictionary) -> void:
	var new_bullet = bullet.instantiate()
	new_bullet.bullet_speed = bullet_speed
	new_bullet.global_position = attack["bullet_position"]
	new_bullet.bullet_direction = attack["bullet_direction"]
	new_bullet.name = attack["bullet_id"]
	player.get_parent().add_child(new_bullet)
	player.arm_player.play(attack_animation)


func simulate_attack(aim_direction: Vector2) -> void:
	if ammunition <= 0:
		return
	ammunition -= 1
	reload_timer.start()
	
	player.sprite.scale.x = player.facing
	player.right_shoulder.look_at(player.right_shoulder.global_position + aim_direction)
	player.arm_player.current_animation = aim_animation
	player.arm_player.seek(0, true)
	
	var new_bullet = bullet.instantiate()
	new_bullet.bullet_speed = bullet_speed
	new_bullet.bullet_damage = bullet_damage
	new_bullet.global_position = marker.global_position
	new_bullet.bullet_direction = aim_direction
	new_bullet.self_hit = self_hit
	new_bullet.player_id = player.name
	new_bullet.name = player.name + str(weapon_number) + str(bullet_counter)
	bullet_counter += 1 
	player.get_parent().add_child(new_bullet)
	var attack := {
		"bullet_position" : marker.global_position,
		"bullet_direction" : aim_direction,
		"bullet_id" : new_bullet.name,
	}
	player.get_parent().send_attack_event(int(player.name), weapon_number, attack) 
	
	player.attacking = true
	
	player.arm_player.play(attack_animation)
	await player.arm_player.animation_finished
	
	player.attacking = false
