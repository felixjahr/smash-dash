class_name Weapon
extends Node2D

const AMMUNITION_BAR_SEGMENT := preload("res://weapons/ammunition_bar_segment.tscn")

@export var self_hit: bool = false
@export var aim_animation: String
@export var attack_animation: String
@export var max_ammunition: int

var ammunition: int

var weapon_number: int
var player: CharacterBody2D
var ammunition_bar: HBoxContainer

@onready var reload_timer := $ReloadTimer


func _ready() -> void:
	if OS.has_feature("match"):
		ammunition = max_ammunition


func set_ammunition_bar(ammunition_bar: HBoxContainer):
	for i in max_ammunition:
		var new_ammunition_bar_segment = AMMUNITION_BAR_SEGMENT.instantiate()
		ammunition_bar.add_child(new_ammunition_bar_segment)
	self.ammunition_bar = ammunition_bar


func animate_ammunition_bar(ammunition: int):
	for animation_bar_segment in ammunition_bar.get_children():
		animation_bar_segment.value = 0
	for i in ammunition:
		ammunition_bar.get_child(i).value = 100


func animate_aim(aim_direction: Vector2) -> void:
	pass


func animate_attack_event(attack: Dictionary) -> void:
	pass


func simulate_attack(aim_direction: Vector2) -> void:
	pass


func _on_reload_timer_timeout() -> void:
	if ammunition >= max_ammunition:
		return
	ammunition += 1
	if ammunition < max_ammunition:
		reload_timer.start()
