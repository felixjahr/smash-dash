extends Node2D

const SPEED := 2000

var bullet_direction: Vector2
var damage: int


func setup(bullet_position: Vector2, bullet_direction: Vector2, damage: int) -> void:
	global_position = bullet_position
	self.bullet_direction = bullet_direction
	self.damage = damage
	rotation = bullet_direction.angle()


func _physics_process(delta: float) -> void:
	global_position += bullet_direction * SPEED * delta


func _on_hitbox_area_entered(area: Area2D) -> void:
	area.get_parent().simulate_hit(damage)
	queue_free()
