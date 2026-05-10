extends TextureButton

const ABILITIES = {
	"dash" : ["res://ui/overlay/ability_button/dash_grey.png", "res://ui/overlay/ability_button/dash_color.png"],
	"double_jump" : ["res://ui/overlay/ability_button/double_jump_grey.png", "res://ui/overlay/ability_button/double_jump_color.png"],
}

@onready var cooldown_bar = $TextureProgressBar


func setup_ability(new_ability_id: String) -> void:
	if ABILITIES.has(new_ability_id):
		texture_normal = load(ABILITIES[new_ability_id][0])
		cooldown_bar.texture_progress = load(ABILITIES[new_ability_id][1])


func update_cooldown_visuals(percent: float) -> void:
	cooldown_bar.value = percent
	disabled = percent < 100.0
