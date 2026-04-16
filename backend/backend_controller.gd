extends Node

const ROOM_SIZE := 2

const BACKEND_PORT := 8000

#const GAME_IP := "35.198.127.12"
const GAME_IP := "127.0.0.1"
const GAME_BASE_PORT := 9000
const GAME_PORT_RANGE_SIZE := 1000

#const SERVER_PATH := "/home/felixjahr/server.x86_64"
const SERVER_PATH := "/usr/local/bin/docker"

var rooms: Dictionary[String, Dictionary] = {}
var next_game_port := GAME_BASE_PORT

@onready var net := $Net/BackendNet


func _ready() -> void:
	net.connect("room_created", _on_net_room_created)
	net.connect("room_joined", _on_net_room_joined)
	net.create_server(BACKEND_PORT)


func _on_net_room_created(pid: int) -> void:
	var code := _generate_room_code()
	
	var room := {
		"members": [pid],
		"game_id": "draft",
		"map_id": Data.MAPS.keys().pick_random(),
	}
	rooms[code] = room
	
	net.send_room_code(pid, code)


func _on_net_room_joined(pid: int, code: String) -> void:
	if not rooms.has(code):
		return
	
	var room: Dictionary = rooms[code]
	room["members"].append(pid)
	
	if room["members"].size() == ROOM_SIZE:
		_start_server_for_room(code)


func _start_server_for_room(code: String) -> void:
	var room: Dictionary = rooms[code]
	room["port"] = next_game_port
	next_game_port = GAME_BASE_PORT + ((next_game_port - GAME_BASE_PORT + 1) % GAME_PORT_RANGE_SIZE)
	
	#var args := [
		#"--headless",
		#"port=" + str(room["port"]),
		#"code=" + code,
		#"game_id=" + room["game_id"],
		#"map_id=" + room["map_id"],
	#]
	var args := [
		"run", "--rm",
		"--platform", "linux/amd64",
		"-p", str(room["port"]) + ":" + str(room["port"]) + "/udp",
		"-v", "/Users/felixjahr/Documents/Projects/Stickman Draft Game/export/server:/app",
		"ubuntu:24.04",
		"/app/server.x86_64",
		"--headless",
		"port=" + str(room["port"]),
		"code=" + code,
		"game_id=" + room["game_id"],
		"map_id=" + room["map_id"],
	]
	
	var server_pid := OS.create_process(SERVER_PATH, args)

	for pid in room["members"]:
		net.send_room_start(pid, room["port"], GAME_IP)


func _generate_room_code() -> String:
	var code: String
	while not code or rooms.has(code):
		code = str(randi_range(0, 9999)).pad_zeros(4)
	return code
