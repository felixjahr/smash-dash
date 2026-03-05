extends Node

@onready var net = $Net
@onready var game = $Game


func _ready() -> void:
	net.start_match()
	game.start_match()
