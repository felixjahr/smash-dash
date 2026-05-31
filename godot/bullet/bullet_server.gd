extends Node2D

var speed: int
var damage: int
var self_hit: bool
var range: int

var direction: Vector2
var player_id: String
var bullet_id: String

@onready var hitbox := $Hitbox
@onready var arena := $Arena
@onready var start_position := global_position


func _ready() -> void:
	rotation = direction.angle()


func tick(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.distance_to(start_position) >= range:
		get_parent().get_parent().despawn_bullet(bullet_id)


func _on_hitbox_area_entered(area: Area2D) -> void:
	if not self_hit and area.get_parent().player_id == player_id:
		return
	area.get_parent().apply_hit(damage, player_id)
	get_parent().get_parent().despawn_bullet(bullet_id)


func _on_hitbox_body_entered(body: Node2D) -> void:
	get_parent().get_parent().despawn_bullet(bullet_id)


func _on_arena_area_exited(area: Area2D) -> void:
	get_parent().get_parent().despawn_bullet(bullet_id)
