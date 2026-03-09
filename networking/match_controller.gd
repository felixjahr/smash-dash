extends Node

@onready var game = $Game


func _ready() -> void:
	game.start_match()
