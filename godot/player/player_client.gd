extends Node2D

const HEART := preload("res://player/heart.tscn")
const WEAPON_AMMUNITION_BAR := preload("res://player/weapon_ammunition_bar.tscn")
const WEAPON_AMMUNITION_BAR_SEGMENT := preload("res://player/weapon_ammunition_bar_segment.tscn")

var player_name: String

var local := false
var last_hit := -1
var last_ability := -1
var armour_id: String
var weapon_ids: Array[String] = []

var camera: Camera2D
var weapon_sprites: Array[Sprite2D] = []
var weapon_ammunition_bars: Array[HBoxContainer] = []

@onready var status := $Status
@onready var name_label := $Status/NameLabel
@onready var heart_container := $Status/HeartContainer
@onready var health_bar := $Status/HealthBar
@onready var weapon_ammunition_bar_container := $Status/WeaponAmmunitionBarContainer
@onready var sprite := $Sprite
@onready var arm_player := $ArmPlayer
@onready var body_player := $BodyPlayer
@onready var right_shoulder := $Sprite/RightShoulder
@onready var weapon_pivot := $Sprite/RightShoulder/RightLowerArm/WeaponPivot
@onready var armour_sprites := [
	$Sprite/LeftShoulder/LeftUpperArm/ArmourLeftUpperArm,
	$Sprite/LeftShoulder/LeftLowerArm/ArmourLeftLowerArm,
	$Sprite/LeftLowerLeg/ArmourLeftLowerLeg,
	$Sprite/LeftUpperLeg/ArmourLeftUpperLeg,
	$Sprite/LowerTorso/ArmourLowerTorso,
	$Sprite/RightUpperLeg/ArmourRightUpperLeg,
	$Sprite/RightLowerLeg/ArmourRightLowerLeg,
	$Sprite/UpperTorso/ArmourUpperTorso,
	$Sprite/Head/ArmourHead,
	$Sprite/RightShoulder/RightUpperArm/ArmourRightUpperArm,
	$Sprite/RightShoulder/RightLowerArm/ArmourRightLowerArm,
]


func _ready() -> void:
	name_label.text = player_name


func apply_snapshot(snapshot: PlayerSnapshot) -> void:	
	global_position = snapshot.position
	health_bar.value = snapshot.health
	
	_update_hearts(snapshot)
	_update_camera()
	_update_hit_effect(snapshot)
	_update_ability_state(snapshot)
	_update_armour(snapshot)
	_update_weapons(snapshot)
	_update_weapon_visiblity(snapshot)
	_update_ammunition_bars(snapshot)
	_update_facing(snapshot)
	_update_body_animation(snapshot)
	_update_arm_animation(snapshot)


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


func _update_hit_effect(snapshot: PlayerSnapshot) -> void:
	if not local and last_hit == -1:
		last_hit = snapshot.last_hit
	if snapshot.last_hit > last_hit:
		last_hit = snapshot.last_hit
		var hit_tween = get_tree().create_tween()
		hit_tween.tween_property(sprite.material, "shader_parameter/flash_amount", 1.0, 0.1)
		hit_tween.parallel().tween_property(sprite.material, "shader_parameter/reveal_amount", 1.0, 0.1)
		hit_tween.tween_interval(0.2)
		hit_tween.tween_property(sprite.material, "shader_parameter/flash_amount", 0.0, 0.1)
		hit_tween.parallel().tween_property(sprite.material, "shader_parameter/reveal_amount", 0.0, 0.1)


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
	if snapshot.weapon_ids == weapon_ids:
		return
	
	var target_count := snapshot.weapon_ids.size()
	while weapon_ids.size() > target_count:
		weapon_sprites.pop_back().queue_free()
		weapon_ammunition_bars.pop_back().queue_free()
		weapon_ids.pop_back()
	if weapon_ids.size() < target_count:
		weapon_sprites.resize(target_count)
		weapon_ammunition_bars.resize(target_count)
		weapon_ids.resize(target_count)
	
	for i in snapshot.weapon_ids.size():
		var snapshot_weapon_id = snapshot.weapon_ids[i]
		if snapshot_weapon_id == weapon_ids[i]:
			continue
		weapon_ids[i] = snapshot_weapon_id
		
		var weapon := Data.WEAPON[snapshot_weapon_id]
		_setup_weapon_sprite(i, weapon)
		_setup_ammunition_bar(i, weapon)


func _setup_weapon_sprite(index: int, weapon: Weapon) -> void:
	if weapon_sprites[index]:
		weapon_sprites[index].queue_free()
	var new_weapon_sprite = Sprite2D.new()
	new_weapon_sprite.texture = weapon.sprite_texture
	new_weapon_sprite.offset = weapon.sprite_offset
	weapon_pivot.add_child(new_weapon_sprite)
	weapon_sprites[index] = new_weapon_sprite


func _setup_ammunition_bar(index: int, weapon: Weapon) -> void:
	if weapon_ammunition_bars[index]:
		weapon_ammunition_bars[index].queue_free()
	var new_weapon_ammunition_bar = WEAPON_AMMUNITION_BAR.instantiate()
	weapon_ammunition_bar_container.add_child(new_weapon_ammunition_bar)
	weapon_ammunition_bar_container.move_child(new_weapon_ammunition_bar, index)
	weapon_ammunition_bars[index] = new_weapon_ammunition_bar
	for j in weapon.max_ammunition:
		var new_weapon_ammunition_bar_segment = WEAPON_AMMUNITION_BAR_SEGMENT.instantiate()
		weapon_ammunition_bars[index].add_child(new_weapon_ammunition_bar_segment)


func _update_weapon_visiblity(snapshot: PlayerSnapshot) -> void:
	for weapon_sprite in weapon_sprites:
		weapon_sprite.hide()
	weapon_sprites[snapshot.current_weapon].show()


func _update_ammunition_bars(snapshot: PlayerSnapshot) -> void:
	for i in snapshot.weapon_ammunitions.size():
		for segment in weapon_ammunition_bars[i].get_children():
			segment.value = 0
		for j in snapshot.weapon_ammunitions[i]:
			weapon_ammunition_bars[i].get_child(j).value = 100


func _update_facing(snapshot: PlayerSnapshot) -> void:
	sprite.scale.x = snapshot.facing


func _update_body_animation(snapshot: PlayerSnapshot) -> void:
	if not snapshot.is_on_floor:
		body_player.play("jump")
	elif snapshot.velocity.x != 0:
		body_player.play("run")
	else:
		body_player.play("idle")


func _update_arm_animation(snapshot: PlayerSnapshot) -> void:
	var weapon := Data.WEAPON[snapshot.weapon_ids[snapshot.current_weapon]]
	
	if snapshot.attacking:
		arm_player.play(weapon.attack_animation)
		return
	
	var aim_direction := snapshot.weapon_aim_directions[snapshot.current_weapon]
	if aim_direction != Vector2.ZERO:
		right_shoulder.look_at(right_shoulder.global_position + aim_direction)
		arm_player.play(weapon.aim_animation)
	else:
		right_shoulder.rotation = 0
		arm_player.play(body_player.current_animation)
