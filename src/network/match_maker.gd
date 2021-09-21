extends Node

signal match_found(player_side)

const MATCHMAKER_IP := "localhost"
const MATCHMAKER_PORT := 65001

master var players_searching_game := []


func _ready() -> void:
	custom_multiplayer = MultiplayerAPI.new();
	custom_multiplayer.set_root_node(self)
	pause_mode = Node.PAUSE_MODE_PROCESS


func _process(_delta: float) -> void:
	if custom_multiplayer.has_network_peer():
		custom_multiplayer.poll()


func create_match_when_data_channel_is_ready(player_side: int) -> void:
	if Netcode.game_data_channel.get_ready_state() == WebRTCDataChannel.STATE_OPEN:
		get_tree().disconnect("idle_frame", self, "create_match_when_data_channel_is_ready")
		match_found(player_side)


master func start_match_maker() -> void:
	var socket := WebSocketServer.new()
	(socket as WebSocketServer).listen(MATCHMAKER_PORT, PoolStringArray(["ludus"]), true)
	custom_multiplayer.network_peer = socket
	custom_multiplayer.connect("network_peer_connected", self, "player_requested_match")
	custom_multiplayer.connect("network_peer_disconnected", self, "player_stopped_match_request")


master func player_requested_match(player_id: int) -> void:
	print("player_requested_match: ", player_id)
	if players_searching_game.empty():
		players_searching_game.push_back(player_id)
	else:
		var opponent_id: int = players_searching_game.pop_front()
		rpc_id(player_id, "create_match_with", opponent_id)


master func player_stopped_match_request(player_id: int) -> void:
	players_searching_game.erase(player_id)


puppet func connect_to_match_maker() -> void:
	Netcode.create_webrtc_peer()

	var socket := WebSocketClient.new()
	(socket as WebSocketClient).connect_to_url("ws://" + MATCHMAKER_IP + ":" + str(MATCHMAKER_PORT), PoolStringArray(["ludus"]), true)
	custom_multiplayer.network_peer = socket


puppet func create_match_with(opponent_id: int) -> void:
	print("create_match_with: ", opponent_id)
	Netcode.game_webrtc_connection.connect("session_description_created", self, "send_remote_description", [opponent_id])
	Netcode.game_webrtc_connection.connect("ice_candidate_created", self, "send_ice_candidate", [opponent_id])
	get_tree().connect("idle_frame", self, "create_match_when_data_channel_is_ready", [Globals.Side.LEFT])
	Netcode.game_webrtc_connection.create_offer()


puppet func send_remote_description(type: String, sdp: String, opponent_id: int) -> void:
	print("send_remote_description: ", opponent_id)
	Netcode.game_webrtc_connection.set_local_description(type, sdp)
	rpc_id(opponent_id, "receive_remote_description", type, sdp)


remote func receive_remote_description(type: String, sdp: String) -> void:
	print("receive_remote_description: ", type)
	if type == "offer":
		Netcode.game_webrtc_connection.connect("session_description_created", self, "send_remote_description", [custom_multiplayer.get_rpc_sender_id()])
		Netcode.game_webrtc_connection.connect("ice_candidate_created", self, "send_ice_candidate", [custom_multiplayer.get_rpc_sender_id()])
		get_tree().connect("idle_frame", self, "create_match_when_data_channel_is_ready", [Globals.Side.RIGHT])
	Netcode.game_webrtc_connection.set_remote_description(type, sdp)


puppet func send_ice_candidate(media: String, index: int, name: String, opponent_id: int) -> void:
	print("send_ice_candidate: ", opponent_id)
	rpc_id(opponent_id, "receive_ice_candidate", media, index, name)


remote func receive_ice_candidate(media: String, index: int, name: String) -> void:
	print("receive_ice_candidate: ", name)
	Netcode.game_webrtc_connection.add_ice_candidate(media, index, name)


remote func match_found(player_side: int) -> void:
	emit_signal("match_found", player_side)
