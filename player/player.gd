extends CharacterBody2D

const WEAPONS := {
	"gun" : preload("res://weapons/ranged/gun/gun.tscn"),
	"rifle" : preload("res://weapons/ranged/rifle/rifle.tscn"),
	"sword" : preload("res://weapons/melee/sword/sword.tscn"),
	"spear" : preload("res://weapons/melee/spear/spear.tscn")
}

const ARMOUR := {
	"light_armour" : preload("res://armour/light_armour/light_armour.tres"),
	"heavy_armour" : preload("res://armour/heavy_armour/heavy_armour.tres"),
}

const SPEED := 500.0
const ACCELERATION := 1500.0
const FRICTION := 1200.0
const GRAVITY := 1500.0
const JUMP_FORCE := -1200.0
const KNOCKBACK_DECAY := 10.0

var jumping := false
var attacking := false
var aim_direction_1 := Vector2.ZERO
var aim_direction_2 := Vector2.ZERO
var health := 100
var facing := 1

var weapon_1_id := "spear"
var weapon_2_id := "rifle"
var armour_id := "light_armour"

var camera: Camera2D

var weapon_1: Weapon
var weapon_2: Weapon
var armour: Armour

@onready var sprite := $Sprite
@onready var hurtbox := $Hurtbox
@onready var collision_shape := $CollisionShape2D
@onready var health_bar := $HealthBar
@onready var ammunition_bar_1 := $AmmunitionBar1
@onready var ammunition_bar_2 := $AmmunitionBar2
@onready var arm_player := $ArmPlayer
@onready var body_player := $BodyPlayer
@onready var effect_player := $EffectPlayer
@onready var right_shoulder := $Sprite/RightShoulder
@onready var hitbox := $Sprite/RightShoulder/Hitbox
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
	if not OS.has_feature("match"):
		hurtbox.queue_free()
		hitbox.queue_free()
		collision_shape.queue_free()
	
	var new_weapon_1 = WEAPONS[weapon_1_id].instantiate()
	new_weapon_1.player = self
	new_weapon_1.weapon_number = 1
	weapon_pivot.add_child(new_weapon_1)
	weapon_1 = new_weapon_1
	
	var new_weapon_2 = WEAPONS[weapon_2_id].instantiate()
	new_weapon_2.player = self
	new_weapon_2.weapon_number = 2
	new_weapon_2.hide()
	weapon_pivot.add_child(new_weapon_2)
	weapon_2 = new_weapon_2
	
	if not OS.has_feature("match") and name == str(multiplayer.get_unique_id()):
		new_weapon_1.set_ammunition_bar(ammunition_bar_1)
		new_weapon_2.set_ammunition_bar(ammunition_bar_2)
	
	armour = ARMOUR[armour_id]
	for armour_sprite in armour_sprites:
		armour_sprite.texture = armour.texture


func animate_snapshot(player_snapshot: Dictionary) -> void:
	global_position = player_snapshot["global_position"]
	velocity = player_snapshot["velocity"]
	health_bar.value = player_snapshot["health"]
	
	if camera:
		camera.global_position = global_position
	
	if player_snapshot["jumping"]:
		body_player.play("jump")
	elif velocity.x != 0:
		body_player.play("run")
	else:
		body_player.play("idle")
	
	if not player_snapshot["attacking"]:
		if velocity.x > 0:
			sprite.scale.x = 1
		elif velocity.x < 0:
			sprite.scale.x = -1
		
		if not player_snapshot["aim_direction_1"] == Vector2.ZERO:
			weapon_1.show()
			weapon_2.hide()
			weapon_1.animate_aim(player_snapshot["aim_direction_1"])
		elif not player_snapshot["aim_direction_2"] == Vector2.ZERO:
			weapon_1.hide()
			weapon_2.show()
			weapon_2.animate_aim(player_snapshot["aim_direction_2"])
		else:
			right_shoulder.rotation = 0
			arm_player.play(body_player.current_animation)
	
	if name == str(multiplayer.get_unique_id()):
		weapon_1.animate_ammunition_bar(player_snapshot["ammunition_1"])
		weapon_2.animate_ammunition_bar(player_snapshot["ammunition_2"])


func animate_attack_event(weapon_number: int, attack: Dictionary) -> void:
	get("weapon_" + str(weapon_number)).animate_attack_event(attack)


func animate_ability_event() -> void:
	pass


func animate_hit_event() -> void:
	effect_player.play("hit")


func simulate_input(input: Dictionary, delta: float) -> void:
	var direction = input["direction"]
	var jump_pressed = input["jump_pressed"]
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	elif jump_pressed and not jumping:
		velocity.y = JUMP_FORCE
		jumping = true
	else:
		jumping = false
	
	if not attacking:
		if velocity.x > 0:
			facing = 1
		elif velocity.x < 0:
			facing = -1
		
		if aim_direction_1.length() > 0.2 and input["aim_direction_1"] == Vector2.ZERO:
			weapon_1.simulate_attack(aim_direction_1.normalized())
		aim_direction_1 = input["aim_direction_1"]
		if aim_direction_2.length() > 0.2 and input["aim_direction_2"] == Vector2.ZERO:
			weapon_2.simulate_attack(aim_direction_2.normalized())
		aim_direction_2 = input["aim_direction_2"]
	
	move_and_slide()


func simulate_knockback(position: Vector2, knockback: float) -> void:
	velocity = position.direction_to(global_position) * knockback


func simulate_hit(damage: int) -> void:
	health -= damage
	get_parent().send_hit_event(int(name))
	if health <= 0:
		pass
