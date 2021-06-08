extends Control
class_name PongGame

signal left_scored()
signal right_scored()

const GOALS_TO_WIN := 2

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER}
var game_type: int = GameType.NONE

onready var audio_goal := $AudioGoal as AudioStreamPlayer2D
onready var center := rect_size / 2

var my_goal: PhysicsBody2D
var opponent_goal: PhysicsBody2D

var player_side: int
var ball_moving_side: int = Globals.Side.RIGHT

# == Game State ==
onready var ball := $Ball as Ball

var my_paddle: Paddle
var opponent_paddle: Paddle

var left_score: int
var right_score: int


static func create(game_type_: int, player_side_: int = Globals.Side.LEFT) -> PongGame:
	var game = (load("res://src/pong/pong_game.tscn") as PackedScene).instance() as PongGame
	game.game_type = game_type_
	game.player_side = player_side_
	return game


func _ready():
	if OS.has_touchscreen_ui_hint():
		if game_type == GameType.LOCAL_MULTIPLAYER:
			_add_touchscreen_input(Globals.MobileInput.ONE_HAND, Globals.Side.LEFT, "player_01")
			_add_touchscreen_input(Globals.MobileInput.ONE_HAND, Globals.Side.RIGHT, "player_02")
		else:
			_add_touchscreen_input(UserPreferences.mobile_input, player_side, "player_01")

	match player_side:
		Globals.Side.LEFT:
			my_paddle = $LeftPaddle
			my_goal = $LeftGoal
			opponent_paddle = $RightPaddle
			opponent_goal = $RightGoal
		Globals.Side.RIGHT:
			my_paddle = $RightPaddle
			my_goal = $RightGoal
			opponent_paddle = $LeftPaddle
			opponent_goal = $LeftGoal

	match game_type:
		GameType.NETWORK_MULTIPLAYER:
			_configure_game_as_network_multiplayer()
		GameType.LOCAL_MULTIPLAYER:
			_configure_game_as_local_multiplayer()
		GameType.LOCAL_AI:
			_configure_game_as_local_ai()

	ball.restart(center, Vector2.RIGHT)


func _physics_process(_delta: float):
	if game_type == GameType.NETWORK_MULTIPLAYER:
		GameServer.send_paddle_and_ball_state(my_paddle.position, my_paddle.charge, ball.position)


func _add_touchscreen_input(mobile_input_type: int, side: int, player: String):
	var mobile_input
	match mobile_input_type:
		Globals.MobileInput.ONE_HAND:
			mobile_input = MobileOneHandInput.new()
		Globals.MobileInput.TWO_HANDS:
			mobile_input = MobileTwoHandInput.new()

	mobile_input.set_player(player)
	mobile_input.set_side(side)

	add_child(mobile_input)


func _configure_game_as_network_multiplayer():
	GameServer._socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")

	my_paddle.set_player_type(Paddle.PlayerType.HUMAN_01)
	opponent_paddle.set_player_type(Paddle.PlayerType.NETWORK)
	opponent_goal.set_collision_layer(0)
	opponent_goal.set_collision_mask(0)


func _configure_game_as_local_multiplayer():
	my_paddle.set_player_type(Paddle.PlayerType.HUMAN_01)
	opponent_paddle.set_player_type(Paddle.PlayerType.HUMAN_02)


func _configure_game_as_local_ai():
	my_paddle.set_player_type(Paddle.PlayerType.HUMAN_01)
	opponent_paddle.set_player_type(Paddle.PlayerType.AI_02)

	var ai := Node2D.new()
	ai.set_script(load("res://src/pong/ai/ai.gd"))
	(ai as AI).configure_ai(ball, my_paddle, opponent_paddle)
	add_child(ai)


func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData):
	match match_state.op_code:
		GameServer.OpCodes.SET_PADDLE_BALL_STATE:
			var data: Dictionary = str2var(match_state.data)
			opponent_paddle.set_position(data["paddle_position"])
			opponent_paddle.set_charge(data["paddle_charge"])
			_adjust_ball_latency(data["ball_position"])
		GameServer.OpCodes.BALL_COLLIDED_WITH_PADDLE:
			var data: Dictionary = str2var(match_state.data)
			ball_moving_side = player_side
			ball.apply_collision(data["position"], data["velocity"], data["bonus_velocity"], data["spin"])
		GameServer.OpCodes.GOAL:
			_on_Ball_collided_goal(str2var(match_state.data))


func _on_Ball_collided_goal(side: int):
	_spawn_goal_sfx()
	audio_goal.play()

	match side:
		Globals.Side.LEFT:
			right_score += 1
			emit_signal("right_scored", right_score)
		Globals.Side.RIGHT:
			left_score += 1
			emit_signal("left_scored", left_score)

	if _has_game_ended():
		ball.queue_free()
	else:
		match side:
			Globals.Side.LEFT:
				ball.restart(center, Vector2.RIGHT)
			Globals.Side.RIGHT:
				ball.restart(center, Vector2.LEFT)


func _spawn_goal_sfx():
	var sfx := GoalSfx.create()
	sfx.position = ball.position
	add_child(sfx)


func _has_game_ended() -> bool:
	if left_score == GOALS_TO_WIN:
		match player_side:
			Globals.Side.LEFT:
				_popup_end_game(true, Globals.Side.LEFT)
			Globals.Side.RIGHT:
				_popup_end_game(false, Globals.Side.LEFT)
		return true
	elif right_score == GOALS_TO_WIN:
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
			ball_moving_side = Globals.Side.RIGHT
		Globals.Side.RIGHT:
			ball_moving_side = Globals.Side.LEFT


func _adjust_ball_latency(network_position: Vector2):
	if player_side != ball_moving_side:
		match ball_moving_side:
			Globals.Side.LEFT:
				ball.latency_speed_adjustment = ball.position.x / network_position.x
			Globals.Side.RIGHT:
				ball.latency_speed_adjustment = (ball.position.x - rect_size.x) / (network_position.x - rect_size.x)


func _popup_end_game(won: bool, side: int):
	var end_game_popup : PopupPanel
	if game_type == GameType.LOCAL_MULTIPLAYER:
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

	if game_type == GameType.NETWORK_MULTIPLAYER:
		GameServer.leave_current_match()

	var main_menu := (load("res://src/main_menu/main_menu.tscn") as PackedScene).instance()

	get_tree().get_root().add_child(main_menu)
	get_tree().get_root().remove_child(self)

	self.queue_free()
