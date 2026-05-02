class_name Data
extends RefCounted

const MAPS: Dictionary[String, PackedScene] = {
	"forest": preload("res://data/maps/forest/forest.tscn"),
	"mountains": preload("res://data/maps/mountains/mountains.tscn"),
}

const ARMOUR_IDS: Array[String] = [
	"light_armour",
	"heavy_armour",
]

const ARMOUR: Dictionary[String, Armour] = {
	"light_armour": preload("res://data/items/armours/light_armour/light_armour.tres"),
	"heavy_armour": preload("res://data/items/armours/heavy_armour/heavy_armour.tres"),
}

const WEAPON_IDS: Array[String] = [
	"gun",
	"rifle",
	"sword",
	"spear",
]

const WEAPON: Dictionary[String, Weapon] = {
	"gun": preload("res://data/items/weapons/ranged/gun/gun.tres"),
	"rifle": preload("res://data/items/weapons/ranged/rifle/rifle.tres"),
	"sword": preload("res://data/items/weapons/melee/sword/sword.tres"),
	"spear": preload("res://data/items/weapons/melee/spear/spear.tres"),
}

const ABILITY: Dictionary[String, Ability] = {
	"double_jump": preload("res://data/items/abilities/double_jump/double_jump.tres"),
	"dash": preload("res://data/items/abilities/dash/dash.tres"),
}

const CATEGORIES: Dictionary[String, Dictionary] = {
	"armour": ARMOUR,
	"weapon": WEAPON,
	"ability": ABILITY
}
