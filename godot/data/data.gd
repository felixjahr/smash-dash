class_name Data
extends RefCounted

const MAPS: Dictionary[String, PackedScene] = {
	"forest": preload("res://data/maps/forest/forest.tscn"),
	"mountains": preload("res://data/maps/mountains/mountains.tscn"),
}

const ARMOUR_IDS: Array[String] = [
	"anti_knockback_armour",
	"heavy_armour",
	"light_armour",
	"spike_armour",
]

const ARMOUR: Dictionary[String, Armour] = {
	"anti_knockback_armour": preload("res://data/items/armours/anti_knockback_armour/anti_knockback_armour.tres"),
	"heavy_armour": preload("res://data/items/armours/heavy_armour/heavy_armour.tres"),
	"light_armour": preload("res://data/items/armours/light_armour/light_armour.tres"),
	"spike_armour": preload("res://data/items/armours/spike_armour/spike_armour.tres"),
}

const WEAPON_IDS: Array[String] = [
	"axe",
	"hammer",
	"spear",
	"sword",
	"bazooka",
	"gun",
	"rifle",
	"shotgun",
	"smg",
	"sniper",
]

const MELEE: Dictionary[String, Melee] = {
	#"axe": preload("res://data/items/weapons/melee/axe/axe.tres"),
	#"hammer": preload("res://data/items/weapons/melee/hammer/hammer.tres"),
	"spear": preload("res://data/items/weapons/melee/spear/spear.tres"),
	"sword": preload("res://data/items/weapons/melee/sword/sword.tres"),
	#"bazooka" : preload("res://data/items/weapons/ranged/bazooka/bazooka.tres"),
	#"shotgun": preload("res://data/items/weapons/ranged/shotgun/shotgun.tres"),
	#"smg": preload("res://data/items/weapons/ranged/smg/smg.tres"),
	#"sniper": preload("res://data/items/weapons/ranged/sniper/sniper.tres"),
}


const RANGED: Dictionary[String, Ranged] = {
	"gun": preload("res://data/items/weapons/ranged/gun/gun.tres"),
	"rifle": preload("res://data/items/weapons/ranged/rifle/rifle.tres"),
}


const ABILITY_IDS: Array[String] = [
	"dash",
	"double_jump",
	"invisibility",
	"slam_down",
]

const ABILITY: Dictionary[String, Ability] = {
	"dash": preload("res://data/items/abilities/dash/dash.tres"),
	"double_jump": preload("res://data/items/abilities/double_jump/double_jump.tres"),
	"invisibility": preload("res://data/items/abilities/invisibility/invisibility.tres"),
	"slam_down": preload("res://data/items/abilities/slam_down/slam_down.tres"),
 }

const CATEGORIES: Dictionary[String, Dictionary] = {
	"armour": ARMOUR,
	"melee" : MELEE,
	"ranged": RANGED,
	"ability": ABILITY,
}
