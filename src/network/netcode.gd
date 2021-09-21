extends Node

const INPUT_DELAY  := 7 # Frames
const MAX_ROLLBACK := 8 # Frames

var game_webrtc_connection: WebRTCPeerConnection
var game_data_channel: WebRTCDataChannel

var game_states := []


func _ready() -> void:
	for _i in range(MAX_ROLLBACK):
		game_states.append(0)


func _process(_delta: float) -> void:
	if game_webrtc_connection:
		game_webrtc_connection.poll()


func create_webrtc_peer() -> void:
	game_webrtc_connection = WebRTCPeerConnection.new()
	game_data_channel = game_webrtc_connection.create_data_channel("game", {
			"id": 1,
			"negotiated": true,
			"maxRetransmits": 0,
			"ordered": false
		})


func set_game_state(frame: int, game_state: PoolByteArray) -> void:
	game_states[frame % game_states.size()] = game_state


func get_game_state(frame: int) -> PoolByteArray:
	return game_states[frame % game_states.size()]


class NetPlayer:
	var messages := []


	func _init():
		for _i in range(MAX_ROLLBACK):
			messages.append({"frame": 0, "input": Globals.GameInput.NONE})


	func get_input(frame: int) -> int:
		return messages[(frame - INPUT_DELAY) % messages.size()].input


class LocalPlayer:
	extends NetPlayer


	func send_input(frame: int, input: int) -> void:
		messages[frame % messages.size()] = {"frame": frame, "input": input}
# warning-ignore:unsafe_property_access
		Netcode.game_data_channel.put_packet(var2bytes(messages))


class RemotePlayer:
	extends NetPlayer


	func receive_input(frame: int) -> int:
		var rollback_frame := frame

# warning-ignore:unsafe_property_access
		while Netcode.game_data_channel.get_available_packet_count() > 0:
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
			var remote_messages = bytes2var(Netcode.game_data_channel.get_packet())
			for i in messages.size():
				if remote_messages[i].frame > messages[i].frame:
					# Have we predicted the wrong input?
					if remote_messages[i].input != messages[i].input:
						if remote_messages[i].frame < rollback_frame:
							rollback_frame = remote_messages[i].frame
					messages[i] = remote_messages[i]
		return rollback_frame


	func has_max_rollback_exceeded(frame: int) -> bool:
		return frame > messages[frame % messages.size()].frame + messages.size()


	func set_input(frame: int, input: int) -> void:
		messages[frame % messages.size()].input = input


	func get_input(frame: int) -> int:
		return .get_input(frame) if frame <= messages[frame % messages.size()].frame else predict_input(frame)


	func predict_input(frame: int) -> int:
		return .get_input(frame - 1)
