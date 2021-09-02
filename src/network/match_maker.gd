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


master func start_match_maker() -> void:
	var socket := WebSocketServer.new()
	(socket as WebSocketServer).listen(MATCHMAKER_PORT, PoolStringArray(["ludus"]), true)
	custom_multiplayer.network_peer = socket
	custom_multiplayer.connect("network_peer_connected", self, "player_requested_match")


master func player_requested_match(player_id: int) -> void:
	print("player_requested_match: ", player_id)
	if players_searching_game.empty():
		players_searching_game.push_back(player_id)
	else:
		var opponent_id: int = players_searching_game.pop_front()
		rpc_id(player_id, "create_match_with", opponent_id)


puppet func connect_to_match_maker() -> void:
	Netcode.create_webrtc_peer()

	var socket := WebSocketClient.new()
	(socket as WebSocketClient).connect_to_url("ws://" + MATCHMAKER_IP + ":" + str(MATCHMAKER_PORT), PoolStringArray(["ludus"]), true)
	custom_multiplayer.network_peer = socket


puppet func create_match_with(opponent_id: int) -> void:
	print("create_match_with: ", opponent_id)
	Netcode.game_webrtc_connection.connect("session_description_created", self, "send_remote_description", [opponent_id])
	Netcode.game_webrtc_connection.connect("ice_candidate_created", self, "send_ice_candidate", [opponent_id])
	Netcode.game_webrtc_connection.connect("ice_candidate_created", self, "match_created", [opponent_id])
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
	Netcode.game_webrtc_connection.set_remote_description(type, sdp)


puppet func send_ice_candidate(media: String, index: int, name: String, opponent_id: int) -> void:
	print("send_ice_candidate: ", opponent_id)
	rpc_id(opponent_id, "receive_ice_candidate", media, index, name)


remote func receive_ice_candidate(media: String, index: int, name: String) -> void:
	print("receive_ice_candidate: ", name)
	Netcode.game_webrtc_connection.add_ice_candidate(media, index, name)


puppet func match_created(_media: String, _index: int, _name: String, opponent_id: int) -> void:
	yield(get_tree().create_timer(1.0), "timeout")
	rpc_id(opponent_id, "match_found", Globals.Side.RIGHT)
	yield(get_tree().create_timer(0.05), "timeout")
	match_found(Globals.Side.LEFT)


remote func match_found(player_side: int) -> void:
	emit_signal("match_found", player_side, randi())
