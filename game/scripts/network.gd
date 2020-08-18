extends Node2D

signal game_found()
signal start_game()

const SERVER_IP := "192.168.0.23"
const SERVER_PORT := 40200
const MAX_PLAYERS := 2

var players_connected: int


func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")


func start_server():
	var peer := NetworkedMultiplayerENet.new()
	peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().network_peer = peer


func request_ranked_game():
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client(SERVER_IP, SERVER_PORT)
	get_tree().network_peer = peer


remote func configure_network_game(side: int, rng_seed: int):
	emit_signal("game_found", side, rng_seed)


func _player_connected(_id):
	print("_player_connected: " + str(_id))

	players_connected += 1
	if players_connected == 2:
		if get_tree().is_network_server():
			var rng_seed = randi()
			rpc_id(get_tree().get_network_connected_peers()[0], "configure_network_game", Globals.Side.LEFT, rng_seed)
			rpc_id(get_tree().get_network_connected_peers()[1], "configure_network_game", Globals.Side.RIGHT, rng_seed)
			configure_network_game(Globals.Side.NONE, rng_seed)
		emit_signal("start_game")


func _player_disconnected(_id):
	print("_player_disconnected: " + str(_id))


func _connected_ok():
	print("_connected_ok")


func _connected_fail():
	print("_connected_fail")


func _server_disconnected():
	print("_server_disconnected")
