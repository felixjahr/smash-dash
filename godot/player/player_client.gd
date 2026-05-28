extends Node2D

const HEART := preload("res://player/heart.tscn")
const WEAPON_AMMUNITION_BAR_SEGMENT := preload("res://player/weapon_ammunition_bar_segment.tscn")
const AIM_LINE_COLOR := Color("#99999980")
const AIM_LINE_NO_AMMUNITION_COLOR := Color("#ff000080")
const HEALTH_BAR_COLOR := Color("#a61c1c")
const HEALTH_BAR_LOCAL_COLOR := Color("#1ca638")

var player_name: String

var local := false
var last_ability := -1
var armour_id: String
var melee_id: String
var ranged_id: String

var camera: Camera2D

@onready var status := $Status
@onready var name_label := $Status/NameLabel
@onready var heart_container := $Status/HeartContainer
@onready var health_bar := $Status/HealthBar
@onready var melee_ammunition_bar := $Status/MeleeAmmunitionBar
@onready var ranged_ammunition_bar := $Status/RangedAmmunitionBar
@onready var aim_line := $AimLine
@onready var pivot := $Pivot
@onready var sprite := $Sprite
@onready var animation_player := $AnimationPlayer
@onready var right_shoulder := $Sprite/LowerTorso/UpperTorso/RightShoulder
@onready var left_shoulder := $Sprite/LowerTorso/UpperTorso/LeftShoulder
@onready var armour_sprites := [
	$Sprite/LowerTorso/UpperTorso/LeftShoulder/LeftUpperArm/ArmourLeftUpperArm,
	$Sprite/LowerTorso/UpperTorso/LeftShoulder/LeftUpperArm/LeftLowerArm/ArmourLeftLowerArm,
	$Sprite/LowerTorso/LeftUpperLeg/ArmourLeftUpperLeg,
	$Sprite/LowerTorso/LeftUpperLeg/LeftLowerLeg/ArmourLeftLowerLeg,
	$Sprite/LowerTorso/UpperTorso/ArmourUpperTorso,
	$Sprite/LowerTorso/ArmourLowerTorso,
	$Sprite/LowerTorso/RightUpperLeg/ArmourRightUpperLeg,
	$Sprite/LowerTorso/RightUpperLeg/RightLowerLeg/ArmourRightLowerLeg,
	$Sprite/LowerTorso/UpperTorso/RightShoulder/RightUpperArm/ArmourRightUpperArm,
	$Sprite/LowerTorso/UpperTorso/RightShoulder/RightUpperArm/RightLowerArm/ArmourRightLowerArm,
	$Sprite/LowerTorso/UpperTorso/Head/ArmourHead,
]


func _ready() -> void:
	name_label.text = player_name
	var fill_style: StyleBoxFlat = health_bar.get_theme_stylebox("fill")
	if local:
		fill_style.bg_color = HEALTH_BAR_LOCAL_COLOR
	else:
		fill_style.bg_color = HEALTH_BAR_COLOR


func apply_snapshot(snapshot: PlayerSnapshot) -> void:	
	global_position = snapshot.position
	health_bar.value = snapshot.health
	
	_update_hearts(snapshot)
	_update_camera()
	_update_ability_state(snapshot)
	_update_armour(snapshot)
	_update_weapons(snapshot)
	_update_ammunition_bars(snapshot)
	_update_facing(snapshot)
	_update_animation_player(snapshot)
	_update_aiming(snapshot)


func apply_hit() -> void:
	var hit_tween = get_tree().create_tween()
	hit_tween.tween_property(sprite.material, "shader_parameter/flash_amount", 1.0, 0.1)
	hit_tween.parallel().tween_property(sprite.material, "shader_parameter/reveal_amount", 1.0, 0.1)
	hit_tween.tween_interval(0.2)
	hit_tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, 0.1)
	hit_tween.parallel().tween_property(sprite.material, "shader_parameter/reveal_amount", 0.0, 0.1)


func _update_hearts(snapshot: PlayerSnapshot) -> void:
	if snapshot.hearts == heart_container.get_child_count():
		return
	for child in heart_container.get_children():
		child.queue_free()
	for i in snapshot.hearts:
		var new_heart = HEART.instantiate()
		heart_container.add_child(new_heart)


func _update_camera() -> void:
	if local:
		camera.global_position = global_position


func _update_ability_state(snapshot: PlayerSnapshot) -> void:
	if not local and last_ability == -1:
		last_ability = snapshot.last_ability
	if snapshot.last_ability > last_ability:
		last_ability = snapshot.last_ability
	if snapshot.ability_active:
		match snapshot.ability_id:
			"invisibility":
				if local:
					sprite.material.set_shader_parameter("invisibility_amount", 0.5)
				else:
					status.hide()
					sprite.material.set_shader_parameter("invisibility_amount", 1.0)
	else:
		status.show()
		sprite.material.set_shader_parameter("invisibility_amount", 0.0)


func _update_armour(snapshot: PlayerSnapshot) -> void:
	if snapshot.armour_id == armour_id:
		return
	for armour_sprite in armour_sprites:
		armour_sprite.texture = Data.ARMOUR[snapshot.armour_id].texture
	armour_id = snapshot.armour_id


func _update_weapons(snapshot: PlayerSnapshot) -> void:
	if snapshot.melee_id != melee_id:
		melee_id = snapshot.melee_id
		_setup_ammunition_bar(melee_ammunition_bar, Data.MELEE[melee_id].max_ammunition)
	if snapshot.ranged_id != ranged_id:
		ranged_id = snapshot.ranged_id
		_setup_ammunition_bar(ranged_ammunition_bar, Data.RANGED[ranged_id].max_ammunition)


func _setup_ammunition_bar(ammunition_bar: HBoxContainer, max_ammunition: int) -> void:
	for child in ammunition_bar.get_children():
		ammunition_bar.remove_child(child)
		child.queue_free()
	for j in max_ammunition:
		var new_weapon_ammunition_bar_segment = WEAPON_AMMUNITION_BAR_SEGMENT.instantiate()
		ammunition_bar.add_child(new_weapon_ammunition_bar_segment)


func _update_ammunition_bars(snapshot: PlayerSnapshot) -> void:
	_update_ammunition_bar(melee_ammunition_bar, snapshot.melee_ammunition)
	_update_ammunition_bar(ranged_ammunition_bar, snapshot.ranged_ammunition)


func _update_ammunition_bar(ammunition_bar: HBoxContainer, ammunition: int) -> void:
	for segment in ammunition_bar.get_children():
		segment.value = 0
	for j in mini(ammunition, ammunition_bar.get_child_count()):
		ammunition_bar.get_child(j).value = 100


func _update_facing(snapshot: PlayerSnapshot) -> void:
	sprite.scale.x = snapshot.facing


func _update_animation_player(snapshot: PlayerSnapshot) -> void:
	var animation_name := ""
	
	if snapshot.current_weapon == 0:
		animation_name += snapshot.melee_id
	else:
		animation_name += snapshot.ranged_id
	animation_name += "/"
	
	if not snapshot.is_on_floor:
		animation_name += "jump_"
	elif snapshot.velocity.x != 0:
		animation_name += "run_"
	else:
		animation_name += "idle_"
	
	if snapshot.attacking:
		animation_name += "attack_"
	elif snapshot.aim_direction != Vector2.ZERO:
		animation_name += "aim_"
	
	if snapshot.current_weapon == 0:
		animation_name += snapshot.melee_id
	else:
		animation_name += snapshot.ranged_id
	
	animation_player.play(animation_name)


func _update_aiming(snapshot: PlayerSnapshot) -> void:
	right_shoulder.rotation = 0
	left_shoulder.rotation = 0
	aim_line.hide()
	var weapon: Weapon
	if snapshot.current_weapon == 0:
		weapon = Data.MELEE[snapshot.melee_id]
	else:
		weapon = Data.RANGED[snapshot.ranged_id]
	
	if snapshot.attacking or snapshot.aim_direction != Vector2.ZERO:
		right_shoulder.look_at(right_shoulder.global_position + snapshot.aim_direction)
		if weapon.two_handed:
			left_shoulder.look_at(left_shoulder.global_position + snapshot.aim_direction)
		if local and not snapshot.attacking:
			if weapon is Melee:
				_update_melee_aim_hint(snapshot, weapon)
			else:
				_update_ranged_aim_hint(snapshot, weapon)


func _update_melee_aim_hint(snapshot: PlayerSnapshot, melee: Melee) -> void:
	pass


func _update_ranged_aim_hint(snapshot: PlayerSnapshot, ranged: Ranged) -> void:
	var offset: Vector2 = ranged.bullet_offset
	offset.y *= snapshot.facing
	var aim_start: Vector2 = pivot.global_position + offset.rotated(snapshot.aim_direction.angle())
	var aim_target: Vector2 = aim_start + snapshot.aim_direction * ranged.range
	
	var query := PhysicsRayQueryParameters2D.create(aim_start, aim_target)
	var collision := get_world_2d().direct_space_state.intersect_ray(query)
	var aim_end: Vector2
	if collision:
		aim_end = collision.position
	else:
		aim_end = aim_target
	
	aim_line.show()
	aim_line.width = ranged.aim_hint_width
	aim_line.clear_points()
	aim_line.add_point(aim_line.to_local(aim_start))
	aim_line.add_point(aim_line.to_local(aim_end))
	if snapshot.ranged_ammunition > 0:
		aim_line.default_color = AIM_LINE_COLOR
	else:
		aim_line.default_color = AIM_LINE_NO_AMMUNITION_COLOR
