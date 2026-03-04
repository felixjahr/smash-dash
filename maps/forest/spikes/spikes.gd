extends StaticBody2D


@onready var collision_shape = $Hitbox/CollisionShape2D


func _on_hitbox_area_entered(area: Area2D) -> void:
	collision_shape.set_deferred("disabled", true)
	await get_tree().create_timer(0.2).timeout
	collision_shape.set_deferred("disabled", false)
