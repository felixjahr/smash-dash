extends Node2D

const ARMOUR := {
	"light_armour" : preload("res://armour/light_armour/light_armour.tres"),
	"heavy_armour" : preload("res://armour/heavy_armour/heavy_armour.tres"),
}

const WEAPONS := {
	"gun" : preload("res://weapons/ranged/gun/gun.tres"),
	"sword" : preload("res://weapons/melee/sword/sword.tres"),
}

const WEAPON_AMMUNITION_BAR := preload("res://weapons/weapon_ammunition_bar.tscn")
const WEAPON_AMMUNITION_BAR_SEGMENT := preload("res://weapons/weapon_ammunition_bar_segment.tscn")

var local := false

var armour_id
var weapon_ids: Array[String] = []
var last_hit := -1

var camera: Camera2D
var weapon_sprites: Array[Sprite2D] = []
var weapon_ammunition_bars: Array[HBoxContainer] = []

@onready var sprite := $Sprite
@onready var health_bar := $HealthBar
@onready var arm_player := $ArmPlayer
@onready var body_player := $BodyPlayer
@onready var effect_player := $EffectPlayer
@onready var right_shoulder := $Sprite/RightShoulder
@onready var weapon_ammunition_bar_container := $WeaponAmmunitionBarContainer
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


func apply_snapshot(snapshot: PlayerSnapshot) -> void:	
	global_position = snapshot.position
	health_bar.value = snapshot.health
	
	if local:
		camera.global_position = global_position
	
	if not local and last_hit == -1:
		last_hit = snapshot.last_hit
	if snapshot.last_hit > last_hit:
		last_hit = snapshot.last_hit
		effect_player.play("hit")
	
	if not snapshot.armour_id == armour_id:
		for armour_sprite in armour_sprites:
			armour_sprite.texture = ARMOUR[snapshot.armour_id].texture
		armour_id = snapshot.armour_id
	
	
	
	if not snapshot.weapon_ids == weapon_ids:
		var snapshot_weapon_count := snapshot.weapon_ids.size()
		var weapon_count := weapon_ids.size()
		
		if snapshot_weapon_count < weapon_count:
			for i in weapon_count - snapshot_weapon_count:
				weapon_ammunition_bars.back().queue_free()
				weapon_sprites.back().queue_free()
		weapon_ids.resize(snapshot_weapon_count)
		weapon_ammunition_bars.resize(snapshot_weapon_count)
		weapon_sprites.resize(snapshot_weapon_count)
		
		for i in snapshot.weapon_ids.size():
			var snapshot_weapon_id = snapshot.weapon_ids[i]
			var weapon_id = weapon_ids[i]
			
			if not snapshot_weapon_id == weapon_id:
				if weapon_sprites[i]:
					weapon_sprites[i].queue_free()
				var new_weapon_sprite = Sprite2D.new()
				new_weapon_sprite.texture = WEAPONS[snapshot_weapon_id].sprite_texture
				new_weapon_sprite.offset = WEAPONS[snapshot_weapon_id].sprite_offset
				new_weapon_sprite.use_parent_material = true
				weapon_pivot.add_child(new_weapon_sprite)
				weapon_sprites[i] = new_weapon_sprite
				weapon_ids[i] = snapshot_weapon_id
				
				if not weapon_ammunition_bars[i]:
					var new_weapon_ammunition_bar = WEAPON_AMMUNITION_BAR.instantiate()
					weapon_ammunition_bar_container.add_child(new_weapon_ammunition_bar)
					weapon_ammunition_bars[i] = new_weapon_ammunition_bar
				for weapon_ammunition_bar_segment in weapon_ammunition_bars[i].get_children():
					weapon_ammunition_bar_segment.queue_free()
				for j in WEAPONS[snapshot_weapon_id].max_ammunition:
					var new_weapon_ammunition_bar_segment = WEAPON_AMMUNITION_BAR_SEGMENT.instantiate()
					weapon_ammunition_bars[i].add_child(new_weapon_ammunition_bar_segment)
	
	for weapon_sprite in weapon_sprites:
		weapon_sprite.hide()
	weapon_sprites[snapshot.current_weapon].show()
	
	for i in snapshot.weapon_ammunitions.size():
		for weapon_ammunition_bar_segment in weapon_ammunition_bars[i].get_children():
			weapon_ammunition_bar_segment.value = 0
		for j in snapshot.weapon_ammunitions[i]:
			weapon_ammunition_bars[i].get_child(j).value = 100
	
	if not snapshot.is_on_floor:
		body_player.play("jump")
	elif snapshot.velocity.x != 0:
		body_player.play("run")
	else:
		body_player.play("idle")
	
	sprite.scale.x = snapshot.facing
	
	var weapon: Weapon = WEAPONS[snapshot.weapon_ids[snapshot.current_weapon]]
	if not snapshot.attacking:
		var weapon_aim_direction := snapshot.weapon_aim_directions[snapshot.current_weapon]
		if not weapon_aim_direction == Vector2.ZERO:
			right_shoulder.look_at(right_shoulder.global_position + weapon_aim_direction)
			arm_player.play(weapon.aim_animation)
		else:
			right_shoulder.rotation = 0
			arm_player.play(body_player.current_animation)
	else:
		arm_player.play(weapon.attack_animation)
