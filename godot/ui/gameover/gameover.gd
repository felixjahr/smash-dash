extends Control

var ranking: Array[String]

@onready var continue_button := $CenterContainer/VBoxContainer/Continue


func _ready() -> void:
	if ranking.is_empty():
		$CenterContainer/VBoxContainer/Label.text = "Match ended"
		return
	$CenterContainer/VBoxContainer/Label.text = "The winner is: " + ranking[0]
