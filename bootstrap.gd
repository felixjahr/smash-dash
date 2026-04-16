extends Node


func _ready() -> void:
	if OS.has_feature("server"):
		get_tree().call_deferred("change_scene_to_file", "res://server/server.tscn")
	elif OS.has_feature("backend"):
		get_tree().call_deferred("change_scene_to_file", "res://backend/backend.tscn")
	else:
		get_tree().call_deferred("change_scene_to_file", "res://client/client.tscn")
