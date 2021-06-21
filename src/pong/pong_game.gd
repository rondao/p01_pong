extends Control
class_name PongGame

signal goal_scored()
signal right_scored(score)
signal left_scored(score)

signal game_won_by(side)

const GOALS_TO_WIN := 2

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER}

onready var audio_goal := $AudioGoal as AudioStreamPlayer2D
onready var center := rect_size / 2

# == Game State ==
onready var ball := $Ball as Ball

var players := []

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
			game.add_child(MobileOneHandInput.new().configure(Globals.Side.LEFT))
			game.add_child(MobileOneHandInput.new().configure(Globals.Side.RIGHT))
		else:
			match UserPreferences.mobile_input:
				UserPreferences.MobileInput.ONE_HAND:
					game.add_child(MobileOneHandInput.new().configure(player_side))
				UserPreferences.MobileInput.TWO_HAND:
					game.add_child(MobileTwoHandInput.new().configure(player_side))

	var left_player := {}
	var right_player := {}

	left_player.paddle = game.get_node("LeftPaddle")
	right_player.paddle = game.get_node("RightPaddle")

	match game_type:
		GameType.LOCAL_AI:
			left_player.paddle.add_child(UserPreferences.get_user_paddle_bounce())
			right_player.paddle.add_child(DifferentialBounce.create())
			left_player.input = Game_Input.new(Globals.Side.LEFT)
			right_player.input = AI_Input.new(game.get_node("Ball"), right_player.paddle)
			left_player.net = Netcode.LocalPlayer.new()
			right_player.net = Netcode.LocalPlayer.new()

	game.players.append(Player.new(left_player.net, left_player.input, left_player.paddle))
	game.players.append(Player.new(right_player.net, right_player.input, right_player.paddle))

	Netcode.create_players(left_player.net, right_player.net)
	return game


func _ready():
	ball.connect("collided_left_goal", ball, "restart_left", [center])
	ball.connect("collided_right_goal", ball, "restart_right", [center])

	ball.restart(Vector2.RIGHT, center)


func _physics_process(delta: float):
	var current_frame := get_tree().get_frame()
	for player in players:
		if player.net is Netcode.LocalPlayer:
			player.net.set_input(current_frame, player.input.to_data())
		player.paddle.handle_input(player.net.get_input(current_frame), delta)


func _on_Ball_collided_right_goal():
	emit_signal("goal_scored")
	left_score += 1
	emit_signal("left_scored", left_score)
	if left_score == GOALS_TO_WIN:
		emit_signal("game_won_by", Globals.Side.LEFT)


func _on_Ball_collided_left_goal():
	emit_signal("goal_scored")
	right_score += 1
	emit_signal("right_scored", right_score)
	if right_score == GOALS_TO_WIN:
		emit_signal("game_won_by", Globals.Side.RIGHT)


func spawn_goal_sfx():
	var sfx := GoalSfx.create()
	sfx.position = ball.position
	add_child(sfx)


func popup_end_multiplayer_game(victory_side: int) -> void:
	configure_end_popup(EndGamePopup.create_popup_with_side_victory(victory_side))


func popup_end_game(victory_side: int, player_side: int) -> void:
	configure_end_popup(EndGamePopup.create_popup(victory_side == player_side))


func configure_end_popup(popup: EndGamePopup) -> void:
	get_tree().get_root().add_child(popup)
	popup.connect("hide", self, "return_main_menu")
	popup.popup()
	get_tree().set_pause(true)


func return_main_menu():
	get_tree().set_pause(false)

	var main_menu := (load("res://src/main_menu/main_menu.tscn") as PackedScene).instance()

	get_tree().get_root().add_child(main_menu)
	get_tree().get_root().remove_child(self)

	queue_free()


class Player:
	var net: Netcode.NetPlayer
	var input: Local_Input
	var paddle: Paddle


	func _init(net_: Netcode.NetPlayer, input_: Local_Input, paddle_: Paddle):
		net = net_
		input = input_
		paddle = paddle_
