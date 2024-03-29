extends Node2D

signal game_found()
signal search_failed()

const SERVER_IP := "34.121.135.131"
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
	var peer = WebSocketServer.new()
	peer.listen(SERVER_PORT, PoolStringArray(), true)
	get_tree().network_peer = peer

	connect("game_found", self, "_on_Server_game_found")


func request_ranked_game():
	var peer = WebSocketClient.new()
	if OK != peer.connect_to_url("ws://" + SERVER_IP + ":" + str(SERVER_PORT), PoolStringArray(), true):
		emit_signal("search_failed")
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


func _player_disconnected(_id):
	players_connected -= 1
	print("_player_disconnected: " + str(_id))


func _connected_ok():
	print("_connected_ok")


func _connected_fail():
	emit_signal("search_failed")


func _server_disconnected():
	print("_server_disconnected")


func _on_Server_game_found(side: int, rng_seed: int):
	seed(rng_seed)
	get_tree().get_root().add_child(PongGame.create(PongGame.GameType.SERVER, side))


func disconnect_multiplayer_game():
	players_connected = 0
	(get_tree().network_peer as WebSocketClient).disconnect_from_host()


func is_network_game() -> bool:
	return get_tree().network_peer != null
