extends Node2D
class_name PongGame

signal left_scored()
signal right_scored()

onready var _ball := $Ball as Ball

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER, SERVER}
var _game_type: int = GameType.NONE

var _my_paddle: Paddle
var _opponent_paddle: Paddle

var _my_goal: PhysicsBody2D
var _opponent_goal: PhysicsBody2D

var player_side: int

const goals_to_win := 2
var _left_score := 0
var _right_score := 0


static func create_game(game_type: int, _player_side: int = Globals.Side.LEFT) -> PongGame:
	var game := (load("res://game/scenes/pong_game.tscn") as PackedScene).instance() as PongGame
	game._game_type = game_type
	game.player_side = _player_side
	return game


func _ready():
	if OS.has_touchscreen_ui_hint():
		_add_touchscreen_input()

	match player_side:
		Globals.Side.LEFT:
			_my_paddle = $LeftPaddle
			_my_goal = $LeftGoal
			_opponent_paddle = $RightPaddle
			_opponent_goal = $RightGoal
		Globals.Side.RIGHT:
			_my_paddle = $RightPaddle
			_my_goal = $RightGoal
			_opponent_paddle = $LeftPaddle
			_opponent_goal = $LeftGoal

	match _game_type:
		GameType.SERVER:
			_configure_game_as_server()
		GameType.NETWORK_MULTIPLAYER:
			_configure_game_as_network_multiplayer()
		GameType.LOCAL_MULTIPLAYER:
			_configure_game_as_local_multiplayer()
		GameType.LOCAL_AI:
			_configure_game_as_local_ai()


func _add_touchscreen_input():
	var mobile_input
	match UserPreferences.mobile_input:
		Globals.MobileInput.ONE_HAND:
			mobile_input = (load("res://game/scenes/mobile_inputs/mobile_input_one_hand.tscn") as PackedScene).instance()
		Globals.MobileInput.TWO_HANDS:
			mobile_input = (load("res://game/scenes/mobile_inputs/mobile_input_two_hands.tscn") as PackedScene).instance()

	if GameServer.is_network_game():
		mobile_input.set_side(player_side)

	add_child(mobile_input)


func _configure_game_as_server():
	get_tree().connect("network_peer_disconnected", self, "_on_Network_disconnected")
	get_tree().connect("server_disconnected", self, "_on_Network_disconnected")

	_my_paddle.set_player_type(Paddle.PlayerType.NETWORK)
	_my_goal.set_collision_layer(0)
	_my_goal.set_collision_mask(0)
	_opponent_paddle.set_player_type(Paddle.PlayerType.NETWORK)
	_opponent_goal.set_collision_layer(0)
	_opponent_goal.set_collision_mask(0)


func _configure_game_as_network_multiplayer():
	get_tree().connect("network_peer_disconnected", self, "_on_Network_disconnected")
	get_tree().connect("server_disconnected", self, "_on_Network_disconnected")
	GameServer._socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")

	_my_paddle.set_player_type(Paddle.PlayerType.HUMAN_01)
	_opponent_paddle.set_player_type(Paddle.PlayerType.NETWORK)
	_opponent_goal.set_collision_layer(0)
	_opponent_goal.set_collision_mask(0)


func _configure_game_as_local_multiplayer():
	_my_paddle.set_player_type(Paddle.PlayerType.HUMAN_01)
	_opponent_paddle.set_player_type(Paddle.PlayerType.HUMAN_02)


func _configure_game_as_local_ai():
	_my_paddle.set_player_type(Paddle.PlayerType.HUMAN_01)
	_opponent_paddle.set_player_type(Paddle.PlayerType.AI)


func _on_Timer_timeout():
	if _game_type == GameType.NETWORK_MULTIPLAYER:
		GameServer.send_paddle_position(_my_paddle.position)


func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData):
	match match_state.op_code:
		GameServer.OpCodes.SET_PADDLE_POSITION:
			_opponent_paddle.set_position(str2var(match_state.data))
		GameServer.OpCodes.SET_PADDLE_CHARGE:
			_opponent_paddle.set_charge(str2var(match_state.data))
		GameServer.OpCodes.BALL_COLLIDED_WITH_PADDLE:
			var data: Dictionary = str2var(match_state.data)
			_ball.apply_collision(data["position"], data["velocity"], data["bonus_velocity"], data["spin"])
		GameServer.OpCodes.GOAL:
			_on_Ball_collided_goal(str2var(match_state.data))


func _on_Ball_collided_goal(side: int):
	match side:
		Globals.Side.LEFT:
			_right_score += 1
			emit_signal("right_scored", _right_score)
		Globals.Side.RIGHT:
			_left_score += 1
			emit_signal("left_scored", _left_score)

	if _left_score == goals_to_win:
		match player_side:
			Globals.Side.LEFT:
				_popup_end_game(true, Globals.Side.LEFT)
			Globals.Side.RIGHT:
				_popup_end_game(false, Globals.Side.LEFT)
	elif _right_score == goals_to_win:
		match player_side:
			Globals.Side.LEFT:
				_popup_end_game(false, Globals.Side.RIGHT)
			Globals.Side.RIGHT:
				_popup_end_game(true, Globals.Side.RIGHT)


func _popup_end_game(won: bool, side: int):
	if _game_type == GameType.NETWORK_MULTIPLAYER:
		get_tree().disconnect("network_peer_disconnected", self, "_on_Network_disconnected")
		get_tree().disconnect("server_disconnected", self, "_on_Network_disconnected")

	var end_game_popup : PopupPanel
	if _game_type == GameType.LOCAL_MULTIPLAYER:
		end_game_popup = EndGamePopup.create_popup_with_side_victory(side)
	else:
		end_game_popup = EndGamePopup.create_popup(won)

	get_tree().get_root().add_child(end_game_popup)

	end_game_popup.connect("hide", self, "_on_EndGamePopup_hide")
	end_game_popup.popup()

	get_tree().set_pause(true)


func _on_Network_disconnected(_peer_id := 0):
	if _game_type == GameType.SERVER:
		self.queue_free()
	else:
		_end_game()


func _on_EndGamePopup_hide():
	_end_game()


func _end_game():
	get_tree().set_pause(false)

	if _game_type == GameType.NETWORK_MULTIPLAYER:
		GameServer.leave_current_match()

	var main_menu := (load("res://game/scenes/main_menu.tscn") as PackedScene).instance()

	get_tree().get_root().add_child(main_menu)
	get_tree().get_root().remove_child(self)

	self.queue_free()
