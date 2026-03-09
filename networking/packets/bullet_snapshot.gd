class_name BulletSnapshot
extends RefCounted

var bullet_id: int

var position: Vector2
var speed: int
var direction: Vector2


func to_dict() -> Dictionary:
	return {
		"bullet_id" : bullet_id,
		"position" : position,
		"speed" : speed,
		"direction" : direction,
	}


static func from_dict(data: Dictionary) -> BulletSnapshot:
	var snapshot := BulletSnapshot.new()
	snapshot.bullet_id = data["bullet_id"]
	snapshot.position = data["position"]
	snapshot.speed = data["speed"]
	snapshot.direction = data["direction"]
	return snapshot
