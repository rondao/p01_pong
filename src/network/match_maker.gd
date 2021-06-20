extends Node

signal match_registered(new_match)

const MATCHMAKER_IP := "localhost"
const MATCHMAKER_PORT := 65001

var free_ports := []
var matches := {}


func _ready() -> void:
	custom_multiplayer = MultiplayerAPI.new();
	custom_multiplayer.set_root_node(self)
	pause_mode = Node.PAUSE_MODE_PROCESS


func _process(_delta: float) -> void:
	if custom_multiplayer.has_network_peer():
		custom_multiplayer.poll()


master func start_match_maker() -> void:
	custom_multiplayer.connect("network_peer_disconnected", self, "_remove_match_if_game_server")
	free_ports = range(50000, 65001)

	var peer := NetworkedMultiplayerENet.new()
	peer.create_server(MATCHMAKER_PORT)
	custom_multiplayer.network_peer = peer


master func receive_match_server_registration(ip: String, port: int, max_players: int) -> void:
# warning-ignore:integer_division
	var new_match = Match.new(ip, port, max_players / 2)
	matches[custom_multiplayer.get_rpc_sender_id()] = new_match
	emit_signal("match_registered", new_match)


master func player_joined_a_match(character: int) -> void:
	var game_match := matches[custom_multiplayer.get_rpc_sender_id()] as Match
	game_match.players[character] += 1


master func player_left_a_match(character: int) -> void:
	var server_id := custom_multiplayer.get_rpc_sender_id()
	var game_match := matches[server_id] as Match

	game_match.players[character] -= 1
	if game_match.is_empty():
		matches.erase(server_id)
		# We have to wait for the match to be closed on the Client side
		#  before destroing the Server, otherwise the Client crashes.
		yield(get_tree().create_timer(LevelTemplate.CLOSE_MATCH_DELAY + 1), "timeout")
		rpc_id(server_id, "destroy_match_server")


master func receive_match_request_as(character: int) -> void:
	var who_called := custom_multiplayer.get_rpc_sender_id()

	var best_match := find_best_match(character)
	if not best_match:
		_create_match()
		best_match = yield(self, "match_registered")

	rpc_id(who_called, "connect_to_match", {"ip": best_match.ip, "port": best_match.port})


master func find_best_match(character: int) -> Match:
	var best_match: Match
	for m in matches.values():
		if not m.is_full(character):
			if not best_match:
				best_match = m
			elif m.players[character] < best_match.players[character]:
				best_match = m
	return best_match


master func _remove_match_if_game_server(peer: int) -> void:
	var disconnected_match := matches.get(peer) as Match
	if disconnected_match:
		free_ports.append(disconnected_match.port)
		matches.erase(peer)


master func _create_match() -> void:
	var project_name = ProjectSettings.get_setting("application/config/name")
	var port = free_ports.pop_front()

	OS.execute("./" + project_name + ".x86_64", ["-match_server:" + MATCHMAKER_IP + ":" + str(port)], false)


puppet func connect_to_match_maker() -> void:
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client(MATCHMAKER_IP, MATCHMAKER_PORT)
	custom_multiplayer.network_peer = peer


puppet func disconnect_from_match_maker() -> void:
	custom_multiplayer.set_deferred("network_peer", null)


puppet func destroy_match_server() -> void:
	get_tree().quit()


puppet func connect_to_match(game_match: Dictionary) -> void:
	var peer := NetworkedMultiplayerENet.new()
	peer.create_client(game_match.ip, game_match.port)
	get_tree().network_peer = peer


puppet func send_match_server_registration(ip: String, port: int, max_players: int) -> void:
	rpc_id(1, "receive_match_server_registration", ip, int(port), max_players)


puppet func send_match_request_as(character: int) -> void:
	rpc_id(1, "receive_match_request_as", character)


puppet func send_player_joined_a_match(character: int) -> void:
	rpc_id(1, "player_joined_a_match", character)


puppet func send_player_died_on_match(character: int) -> void:
	rpc_id(1, "player_left_a_match", character)


class Match:
	var ip: String
	var port: int

	var players := {Globals.Characters.PACMAN: 0, Globals.Characters.GHOST: 0}
	var max_player_per_character: int


	func _init(ip_: String, port_: int, max_player_per_character_: int) -> void:
		ip = ip_
		port = port_
		max_player_per_character = max_player_per_character_

	func is_full(character: int) -> bool:
		return players[character] == max_player_per_character

	func is_empty() -> bool:
		return (players[Globals.Characters.PACMAN] == 0
				and players[Globals.Characters.GHOST] == 0)
