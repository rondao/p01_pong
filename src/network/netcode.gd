extends Node

const INPUT_DELAY  := 7 # Frames
const MAX_ROLLBACK := 8 # Frames

var players := []


func create_players(player_01: NetPlayer, player_02: NetPlayer) -> void:
	players.append(player_01)
	players.append(player_02)


class NetPlayer:
	var inputs := PoolIntArray()

	func _init():
		for _i in range(INPUT_DELAY + MAX_ROLLBACK):
			inputs.append(0)


	func get_input(frame: int) -> int:
		return inputs[frame % inputs.size()]


class LocalPlayer:
	extends NetPlayer


	func set_input(frame: int, input: int) -> void:
		inputs[(frame + INPUT_DELAY) % inputs.size()] = input


class RemotePlayer:
	extends NetPlayer

	var predict_frame := 0


	func set_input(frame: int, input: int) -> void:
		inputs[frame % inputs.size()] = input


	func get_input(frame: int) -> int:
		return .get_input(frame) if frame < predict_frame else predict_input(frame)


	func predict_input(frame: int) -> int:
		set_input(frame, .get_input(frame - 1))
		return .get_input(frame)
