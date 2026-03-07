class_name Melee
extends Weapon

@export var damage := 10
@export var knockback := 0

var attacking := false


func _ready() -> void:
	super()
	if OS.has_feature("match"):
		player.hitbox.connect("area_entered", _on_hitbox_area_entered)
		player.hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)


func animate_aim(aim_direction: Vector2) -> void:
	if aim_direction.x > 0:
		player.sprite.scale.x = 1
	else:
		player.sprite.scale.x = -1
	player.right_shoulder.look_at(player.right_shoulder.global_position + aim_direction)
	player.arm_player.play(aim_animation)


func animate_attack_event(attack: Dictionary) -> void:
	player.arm_player.play(attack_animation)


func simulate_attack(aim_direction: Vector2) -> void:
	if ammunition <= 0:
		return
	ammunition -= 1
	reload_timer.start()
	
	player.right_shoulder.look_at(player.right_shoulder.global_position + aim_direction)
	if aim_direction.x > 0:
		player.facing = 1
	else:
		player.facing = -1
	
	player.get_parent().send_attack_event(int(player.name), weapon_number, {}) 
	
	player.attacking = true
	attacking = true
	player.hitbox.get_node("CollisionShape2D").set_deferred("disabled", false)
	
	player.arm_player.play(attack_animation)
	await player.arm_player.animation_finished
	
	player.hitbox.get_node("CollisionShape2D").set_deferred("disabled", true)
	player.attacking = false
	attacking = true


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not attacking:
		return
	if not self_hit and area.get_parent().name == player.name:
		return
	area.get_parent().simulate_hit(damage)
	area.get_parent().simulate_knockback(player.right_shoulder.global_position, knockback)
