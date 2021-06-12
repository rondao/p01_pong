extends Control
class_name PongGame

signal left_scored()
signal right_scored()
signal game_won_by(side)

const GOALS_TO_WIN := 2

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER}
#var game_type: int = GameType.NONE

onready var audio_goal := $AudioGoal as AudioStreamPlayer2D
onready var center := rect_size / 2

var left_goal: PhysicsBody2D
var right_goal: PhysicsBody2D

var ball_moving_side: int = Globals.Side.RIGHT

# == Game State ==
onready var ball := $Ball as Ball

onready var left_paddle := $LeftPaddle as Paddle
onready var right_paddle := $RightPaddle as Paddle

var left_score: int
var right_score: int


static func create(game_type: int, player_side: int = Globals.Side.LEFT) -> PongGame:
	var game = (load("res://src/pong/pong_game.tscn") as PackedScene).instance() as PongGame

	if game_type == GameType.LOCAL_MULTIPLAYER:
		game.connect("game_won_by", game, "popup_end_multiplayer_game")
	else:
		game.connect("game_won_by", game, "popup_end_game", [player_side])

	if OS.has_touchscreen_ui_hint():
		if game_type == GameType.LOCAL_MULTIPLAYER:
			game.add_child(MobileOneHandInput.new().configure(Globals.Side.LEFT, "player_01"))
			game.add_child(MobileOneHandInput.new().configure(Globals.Side.RIGHT, "player_02"))
		else:
			var player_input = "player_01" if player_side == Globals.Side.LEFT else "player_02"
			match UserPreferences.mobile_input:
				UserPreferences.MobileInput.ONE_HAND:
					game.add_child(MobileOneHandInput.new().configure(player_side, player_input))
				UserPreferences.MobileInput.TWO_HAND:
					game.add_child(MobileTwoHandInput.new().configure(player_side, player_input))


#	match game_type:
##		GameType.NETWORK_MULTIPLAYER:
##			GameServer._socket.connect("received_match_state", self, "_on_NakamaSocket_received_match_state")
#		GameType.LOCAL_AI:
#			add_child(AI.new().configure_ai(game.get_node("Ball"), my_paddle))

	return game


func _ready():
	ball.restart(center, Vector2.RIGHT)


#func _physics_process(_delta: float):
#	if game_type == GameType.NETWORK_MULTIPLAYER:
#		GameServer.send_paddle_and_ball_state(my_paddle.position, my_paddle.charge, ball.position)


func _on_Ball_collided_goal(side: int):
	spawn_goal_sfx()
	audio_goal.play()

	match side:
		Globals.Side.LEFT:
			right_score += 1
			emit_signal("right_scored", right_score)
		Globals.Side.RIGHT:
			left_score += 1
			emit_signal("left_scored", left_score)

	if left_score == GOALS_TO_WIN:
		emit_signal("game_won_by", Globals.Side.LEFT)
	elif right_score == GOALS_TO_WIN:
		emit_signal("game_won_by", Globals.Side.LEFT)
	else:
		match side:
			Globals.Side.LEFT:
				ball.restart(center, Vector2.RIGHT)
			Globals.Side.RIGHT:
				ball.restart(center, Vector2.LEFT)


func spawn_goal_sfx():
	var sfx := GoalSfx.create()
	sfx.position = ball.position
	add_child(sfx)


func _on_Ball_collided_paddle(side: int):
	match side:
		Globals.Side.LEFT:
			ball_moving_side = Globals.Side.RIGHT
		Globals.Side.RIGHT:
			ball_moving_side = Globals.Side.LEFT


func popup_end_game(victory_side: int, player_side: int) -> void:
	configure_end_popup(EndGamePopup.create_popup(victory_side == player_side))


func popup_end_multiplayer_game(victory_side: int) -> void:
	configure_end_popup(EndGamePopup.create_popup_with_side_victory(victory_side))


func configure_end_popup(popup: EndGamePopup) -> void:
	get_tree().get_root().add_child(popup)
	popup.connect("hide", self, "return_main_menu")
	popup.popup()
	get_tree().set_pause(true)


func return_main_menu():
	get_tree().set_pause(false)

#	if game_type == GameType.NETWORK_MULTIPLAYER:
#		GameServer.leave_current_match()

	var main_menu := (load("res://src/main_menu/main_menu.tscn") as PackedScene).instance()

	get_tree().get_root().add_child(main_menu)
	get_tree().get_root().remove_child(self)

	queue_free()


#func _on_NakamaSocket_received_match_state(match_state: NakamaRTAPI.MatchData):
#	match match_state.op_code:
#		GameServer.OpCodes.SET_PADDLE_BALL_STATE:
#			var data: Dictionary = str2var(match_state.data)
#			opponent_paddle.set_position(data["paddle_position"])
#			opponent_paddle.set_charge(data["paddle_charge"])
#			_adjust_ball_latency(data["ball_position"])
#		GameServer.OpCodes.BALL_COLLIDED_WITH_PADDLE:
#			var data: Dictionary = str2var(match_state.data)
#			ball_moving_side = player_side
#			ball.apply_collision(data["position"], data["velocity"], data["bonus_velocity"], data["spin"])
#		GameServer.OpCodes.GOAL:
#			_on_Ball_collided_goal(str2var(match_state.data))


#func _adjust_ball_latency(network_position: Vector2):
#	if player_side != ball_moving_side:
#		match ball_moving_side:
#			Globals.Side.LEFT:
#				ball.latency_speed_adjustment = ball.position.x / network_position.x
#			Globals.Side.RIGHT:
#				ball.latency_speed_adjustment = (ball.position.x - rect_size.x) / (network_position.x - rect_size.x)
