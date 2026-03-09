class_name Snapshot
extends RefCounted

var tick: int

var players: Array[PlayerSnapshot]
var bullets: Array[BulletSnapshot]


func to_dict() -> Dictionary:
	return {
		"tick": tick,
		"players": players.map(func(snapshot): return snapshot.to_dict()),
		"bullets": bullets.map(func(snapshot): return snapshot.to_dict())
	}


static func from_dict(data: Dictionary) -> Snapshot:
	var snapshot := Snapshot.new()
	snapshot.tick = data["tick"]
	snapshot.players = []
	for player_data in data["players"]:
		snapshot.players.append(PlayerSnapshot.from_dict(player_data))
	snapshot.bullets = []
	for bullet_data in data["bullets"]:
		snapshot.bullets.append(BulletSnapshot.from_dict(bullet_data))
	return snapshot
