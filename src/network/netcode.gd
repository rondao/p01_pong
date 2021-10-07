extends Node

const INPUT_DELAY  := 7 # Frames
const MAX_ROLLBACK := 8 # Frames

var game_webrtc_connection: WebRTCPeerConnection
var game_data_channel: WebRTCDataChannel
var game_state_channel: WebRTCDataChannel

var game_states := []


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
	game_state_channel = game_webrtc_connection.create_data_channel("state", {
			"id": 2,
			"negotiated": true,
			"maxRetransmits": 0,
			"ordered": false
		})


func set_game_state(idx: int, game_state: PoolByteArray) -> void:
	if idx == 0:
		game_states.push_back(game_state)
	else:
		game_states[idx] = game_state


func get_game_state(idx: int) -> PoolByteArray:
	return game_states[idx]


func game_state_ready_to_send() -> bool:
	return game_states.size() == 2 * MAX_ROLLBACK


func send_game_state() -> void:
	game_state_channel.put_packet(var2bytes(game_states.slice(0, MAX_ROLLBACK)))
	game_states.pop_front()


func receive_game_state() -> Dictionary:
	while game_state_channel.get_available_packet_count() > 0:
		var index := 0
		var remote_states = bytes2var(game_state_channel.get_packet())
		for remote_state_bytes in remote_states:
			var remote_state = bytes2var(remote_state_bytes)
			var game_state = bytes2var(game_states[index])
			if remote_state.frame == game_state.frame:
				if remote_state_bytes != game_states[index]:
					return {"state_match": false, "local_game_state": game_state, "remote_game_state": remote_state}
				index += 1
	return {"state_match": true}


class NetPlayer:
	var messages := []


	func _init():
		for i in range(MAX_ROLLBACK):
			messages.append({"frame": i, "input": Globals.GameInput.NONE})


	func get_input(frame: int) -> int:
		return messages[(frame) % messages.size()].input


class LocalPlayer:
	extends NetPlayer


	func send_input(frame: int, input: int) -> void:
		var delayed_frame := frame + INPUT_DELAY
		if messages[delayed_frame % messages.size()].frame != delayed_frame: # Do not allow an Input to be changed.
			messages[delayed_frame % messages.size()] = {"frame": delayed_frame, "input": input}
#		print("local frame: ", messages)
# warning-ignore:unsafe_property_access
		Netcode.game_data_channel.put_packet(var2bytes(messages))


	func get_input(frame: int) -> int:
		return messages[frame % messages.size()].input


class RemotePlayer:
	extends NetPlayer


	func receive_input(frame: int) -> int:
		var rollback_frame := frame

# warning-ignore:unsafe_property_access
		while Netcode.game_data_channel.get_available_packet_count() > 0:
# warning-ignore:unsafe_property_access
# warning-ignore:unsafe_property_access
			var remote_messages = bytes2var(Netcode.game_data_channel.get_packet())
#			print("remote frame: ", remote_messages)
			for i in messages.size():
				if (remote_messages[i].frame > messages[i].frame
					and remote_messages[i].frame < frame + MAX_ROLLBACK): # Ignore messages for frames we didn't processed yet.
					# Have we predicted the wrong input?
					if remote_messages[i].input != messages[i].input:
						if remote_messages[i].frame < rollback_frame:
							rollback_frame = remote_messages[i].frame
					messages[i] = remote_messages[i]
		return rollback_frame


	func has_max_rollback_exceeded(frame: int) -> bool:
#		print(frame, " - " ,messages)
		return frame > messages[frame % messages.size()].frame + MAX_ROLLBACK


	func set_input(frame: int, input: int) -> void:
		messages[frame % messages.size()].input = input


	func get_input(frame: int) -> int:
		return .get_input(frame) if frame <= messages[frame % messages.size()].frame else predict_input(frame)


	func predict_input(frame: int) -> int:
		var predicted_input := .get_input(frame - 1)
#		print("predict ", predicted_input, " for ", frame)
		set_input(frame, predicted_input)
		return predicted_input
