extends Node

signal game_found()

const NAKAMA_IP_SERVER := "35.198.29.57"

onready var _client := Nakama.create_client("defaultkey", NAKAMA_IP_SERVER, 7350, "http", Nakama.DEFAULT_TIMEOUT, NakamaLogger.LOG_LEVEL.VERBOSE)

var _socket: NakamaSocket 
var _session: NakamaSession

var _match_id: String
var _self_id: String

var _players: Array

enum OpCodes {
	CONFIGURE_GAME = 1,
	SET_PADDLE_POSITION,
	BALL_COLLIDED_WITH_PADDLE,
	GOAL
}


func _ready():
	_session = yield(register_async(), "completed")
	yield(connect_to_server_async(), "completed")


func register_async() -> NakamaSession:
	var id = OS.get_unique_id() if OS.get_name() != "HTML5" else "default_id"
	
	var session: NakamaSession = yield(_client.authenticate_custom_async(id), "completed")

	print("=== RONDAO : DEBUG === register_async")
	return session if not session.is_exception() else null


func connect_to_server_async():
	_socket = Nakama.create_socket_from(_client)

	var result: NakamaAsyncResult = yield(_socket.connect_async(_session), "completed")

	if not result.is_exception():
		_socket.connect("connected", self, "_on_NakamaSocket_connected")
		_socket.connect("closed", self, "_on_NakamaSocket_closed")
		_socket.connect("received_error", self, "_on_NakamaSocket_received_error")
		_socket.connect("received_matchmaker_matched", self, "_on_NakamaSocket_received_matchmaker_matched")
		_socket.connect("received_match_presence", self, "_on_NakamaSocket_received_match_presence")
		_socket.connect("received_channel_message", self, "_on_NamakaSocket_received_channel_message")

	print("=== RONDAO : DEBUG === connect_to_server_async")


func request_matchmaking():
	var matchmaker_ticket: NakamaRTAPI.MatchmakerTicket = \
		yield(_socket.add_matchmaker_async("*", 2, 2), "completed")

	if matchmaker_ticket.is_exception():
		print("=== RONDAO : DEBUG === matchmaker_ticket.is_exception()")
		return

	print("=== RONDAO : DEBUG === request_matchmaking")


func _on_NakamaSocket_received_matchmaker_matched(p_matched: NakamaRTAPI.MatchmakerMatched):
	var joined_match: NakamaRTAPI.Match = yield(_socket.join_matched_async(p_matched), "completed")
	if joined_match.is_exception():
		print("=== RONDAO : DEBUG ===  _on_matchmaker_matched: An error occured: %s" % joined_match)
		return
	print("=== RONDAO : DEBUG ===  _on_matchmaker_matched: Joined match: %s" % [joined_match.match_id])
	_match_id = joined_match.match_id
	_self_id = joined_match.self_user.user_id
	print("=== RONDAO : DEBUG ===  _on_matchmaker_matched: self_user: %s" % [joined_match.self_user.user_id])
	for presence in joined_match.presences:
		print("=== RONDAO : DEBUG ===  _on_matchmaker_matched: User id %s name %s'." % [presence.user_id, presence.username])
		_players.append(presence)
		_check_game_ready()


func _on_NakamaSocket_received_match_presence(p_presence: NakamaRTAPI.MatchPresenceEvent):
	for p in p_presence.joins:
		print("=== RONDAO : DEBUG ===  _on_match_presence: Opponent joins: %s" % p.user_id)
		_players.append(p)
		_check_game_ready()
	for p in p_presence.leaves:
		print("=== RONDAO : DEBUG ===  _on_match_presence: Opponent leaves: %s" % p.user_id)
		_players.erase(p)


func _check_game_ready():
	if _players.size() >= 2:
		if _self_id == _players[0].user_id:
			emit_signal("game_found", Globals.Side.LEFT, _match_id.hash())
		elif _self_id == _players[1].user_id:
			emit_signal("game_found", Globals.Side.RIGHT, _match_id.hash())


func send_paddle_position(position: Vector2):
	_socket.send_match_state_async(_match_id, OpCodes.SET_PADDLE_POSITION, var2str(position))
