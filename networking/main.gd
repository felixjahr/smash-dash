extends Node


func _ready() -> void:
	if OS.has_feature("match"):
		get_tree().call_deferred("change_scene_to_file", "res://networking/match.tscn")
	elif OS.has_feature("lobby"):
		get_tree().call_deferred("change_scene_to_file", "res://networking/lobby.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://networking/client.tscn")
