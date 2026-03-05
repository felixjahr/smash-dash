extends Node2D

const SPEED := 2000

var direction: Vector2

func _ready() -> void:
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta
	
