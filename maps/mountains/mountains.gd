extends Node2D


@onready var camera := $Camera2D
@onready var arena := $Arena
@onready var collision_shapes := [
	$StaticBody2D/CollisionShape2D,
	$StaticBody2D/CollisionShape2D2,
	$StaticBody2D/CollisionShape2D3,
]


func _ready() -> void:
	if not OS.has_feature("match"):
		for collision_shape in collision_shapes:
			arena.queue_free()
			collision_shape.queue_free()
