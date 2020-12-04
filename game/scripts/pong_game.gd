extends Control
class_name PongGame

signal left_scored()
signal right_scored()

export(PackedScene) var GoalSfx: PackedScene

onready var _audio_goal := $AudioGoal as AudioStreamPlayer2D
onready var _ball := $Ball as Ball
onready var _center := rect_size / 2

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER}
var _game_type: int = GameType.NONE

var _my_paddle: Paddle
var _opponent_paddle: Paddle

var _my_goal: PhysicsBody2D
var _opponent_goal: PhysicsBody2D

var player_side: int
var _ball_moving_side: int = Globals.Side.RIGHT

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
		if _game_type == GameType.LOCAL_MULTIPLAYER:
			_add_touchscreen_input(Globals.MobileInput.ONE_HAND, Globals.Side.LEFT, "player_01")
			_add_touchscreen_input(Globals.MobileInput.ONE_HAND, Globals.Side.RIGHT, "player_02")
		else:
			_add_touchscreen_input(UserPreferences.mobile_input, player_side, "player_01")

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
		GameType.NETWORK_MULTIPLAYER:
			_configure_game_as_network_multiplayer()
		GameType.LOCAL_MULTIPLAYER:
			_configure_game_as_local_multiplayer()
		GameType.LOCAL_AI:
			_configure_game_as_local_ai()

	_ball.restart(_center, Vector2.RIGHT)


func _physics_process(_delta: float):
	if _game_type == GameType.NETWORK_MULTIPLAYER:
		GameServer.send_paddle_and_ball_state(_my_paddle.position, _my_paddle.charge, _ball.position)


func _add_touchscreen_input(mobile_input_type: int, side: int, player: String):
	var mobile_input
	match mobile_input_type:
		Globals.MobileInput.ONE_HAND:
			mobile_input = (load("res://game/scenes/mobile_inputs/mobile_input_one_hand.tscn") as PackedScene).instance()
		Globals.MobileInput.TWO_HANDS:
			mobile_input = (load("res://game/scenes/mobile_inputs/mobile_input_two_hands.tscn") as PackedScene).instance()

	mobile_input.set_player(player)
	mobile_input.set_side(side)

	add_child(mobile_input)


func _configure_game_as_network_multiplayer():
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


func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData):
	print(OS.get_ticks_msec())
	match match_state.op_code:
		GameServer.OpCodes.SET_PADDLE_BALL_STATE:
			var data: Dictionary = str2var(match_state.data)
			_opponent_paddle.set_position(data["paddle_position"])
			_opponent_paddle.set_charge(data["paddle_charge"])
			_adjust_ball_latency(data["ball_position"])
		GameServer.OpCodes.BALL_COLLIDED_WITH_PADDLE:
			var data: Dictionary = str2var(match_state.data)
			_ball_moving_side = player_side
			_ball.apply_collision(data["position"], data["velocity"], data["bonus_velocity"], data["spin"])
		GameServer.OpCodes.GOAL:
			_on_Ball_collided_goal(str2var(match_state.data))


func _on_Ball_collided_goal(side: int):
	_spawn_goal_sfx()
	_audio_goal.play()

	match side:
		Globals.Side.LEFT:
			_right_score += 1
			emit_signal("right_scored", _right_score)
		Globals.Side.RIGHT:
			_left_score += 1
			emit_signal("left_scored", _left_score)

	if _has_game_ended():
		_ball.queue_free()
	else:
		match side:
			Globals.Side.LEFT:
				_ball.restart(_center, Vector2.RIGHT)
			Globals.Side.RIGHT:
				_ball.restart(_center, Vector2.LEFT)


func _spawn_goal_sfx():
	var sfx := GoalSfx.instance() as Node2D
	sfx.position = _ball.position
	add_child(sfx)


func _has_game_ended() -> bool:
	if _left_score == goals_to_win:
		match player_side:
			Globals.Side.LEFT:
				_popup_end_game(true, Globals.Side.LEFT)
			Globals.Side.RIGHT:
				_popup_end_game(false, Globals.Side.LEFT)
		return true
	elif _right_score == goals_to_win:
		match player_side:
			Globals.Side.LEFT:
				_popup_end_game(false, Globals.Side.RIGHT)
			Globals.Side.RIGHT:
				_popup_end_game(true, Globals.Side.RIGHT)
		return true
	return false


func _on_Ball_collided_paddle(side: int):
	match side:
		Globals.Side.LEFT:
			_ball_moving_side = Globals.Side.RIGHT
		Globals.Side.RIGHT:
			_ball_moving_side = Globals.Side.LEFT


func _adjust_ball_latency(network_position: Vector2):
	if player_side != _ball_moving_side:
		match _ball_moving_side:
			Globals.Side.LEFT:
				_ball.latency_speed_adjustment = _ball.position.x / network_position.x
			Globals.Side.RIGHT:
				_ball.latency_speed_adjustment = (_ball.position.x - rect_size.x) / (network_position.x - rect_size.x)


func _popup_end_game(won: bool, side: int):
	var end_game_popup : PopupPanel
	if _game_type == GameType.LOCAL_MULTIPLAYER:
		end_game_popup = EndGamePopup.create_popup_with_side_victory(side)
	else:
		end_game_popup = EndGamePopup.create_popup(won)

	get_tree().get_root().add_child(end_game_popup)

	end_game_popup.connect("hide", self, "_on_EndGamePopup_hide")
	end_game_popup.popup()

	get_tree().set_pause(true)


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
