extends Node

const INPUT_DELAY  := 7 # Frames
const MAX_ROLLBACK := 8 # Frames

var game_webrtc_connection: WebRTCPeerConnection
var game_data_channel: WebRTCDataChannel


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


class NetPlayer:
	var messages := []


	func _init():
		for _i in range(INPUT_DELAY + MAX_ROLLBACK):
			messages.append({"frame": 0, "input": Globals.GameInput.NONE})


	# Virtual
	func get_input(_frame: int) -> int:
		return Globals.GameInput.NONE


class LocalPlayer:
	extends NetPlayer


	func send_input(frame: int, input: int) -> void:
		messages[frame % messages.size()] = {"frame": frame, "input": input}
# warning-ignore:unsafe_property_access
		Netcode.game_data_channel.put_packet(var2bytes(messages))


	func get_input(frame: int) -> int:
		return messages[(frame - INPUT_DELAY) % messages.size()].input


class RemotePlayer:
	extends NetPlayer


	func receive_input() -> void:
# warning-ignore:unsafe_property_access
		while Netcode.game_data_channel.get_available_packet_count() > 0:
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
			var remote_messages = bytes2var(Netcode.game_data_channel.get_packet())
			for i in messages.size():
				if remote_messages[i].frame > messages[i].frame:
					messages[i] = remote_messages[i]


	func set_input(frame: int, input: int) -> void:
		messages[frame % messages.size()].input = input


	func get_input(frame: int) -> int:
		return .get_input(frame) if frame > messages[frame % messages.size()].frame else predict_input(frame)


	func predict_input(frame: int) -> int:
		set_input(frame, .get_input(frame - 1))
		return .get_input(frame)
