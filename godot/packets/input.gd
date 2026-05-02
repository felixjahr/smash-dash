class_name PlayerInput
extends Node

const DIRECTION_SCALE := 127.0
const AIM_SCALE := 127.0
const SIGNED_8_BIAS := 128

var tick: int

var direction := 0.0
var jumping := false
var current_weapon := 0
var weapon_aim_directions: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]


func to_packet() -> PackedByteArray:
	var peer := StreamPeerBuffer.new()
	peer.big_endian = false
	peer.put_u32(tick)
	var flags := 0
	if jumping:
		flags |= 1
	peer.put_u8(flags)
	peer.put_u8(clampi(current_weapon, 0, 255))
	peer.put_u8(_encode_signed_8(direction, DIRECTION_SCALE))
	peer.put_u8(weapon_aim_directions.size())
	for aim_direction in weapon_aim_directions:
		peer.put_u8(_encode_signed_8(aim_direction.x, AIM_SCALE))
		peer.put_u8(_encode_signed_8(aim_direction.y, AIM_SCALE))
	return peer.data_array


static func from_packet(packet: PackedByteArray) -> PlayerInput:
	var peer := StreamPeerBuffer.new()
	peer.big_endian = false
	peer.data_array = packet
	var input := PlayerInput.new()
	input.tick = int(peer.get_u32())
	var flags := int(peer.get_u8())
	input.jumping = (flags & 1) != 0
	input.current_weapon = int(peer.get_u8())
	input.direction = _decode_signed_8(int(peer.get_u8()), DIRECTION_SCALE)
	input.weapon_aim_directions = []
	var aim_count := int(peer.get_u8())
	for i in aim_count:
		input.weapon_aim_directions.append(Vector2(
			_decode_signed_8(int(peer.get_u8()), AIM_SCALE),
			_decode_signed_8(int(peer.get_u8()), AIM_SCALE)
		))
	return input


static func _encode_signed_8(value: float, scale: float) -> int:
	return clampi(int(round(value * scale)) + SIGNED_8_BIAS, 0, 255)


static func _decode_signed_8(value: int, scale: float) -> float:
	return float(value - SIGNED_8_BIAS) / scale
