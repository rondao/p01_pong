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

var players: Array

var left_score: int
var right_score: int

var current_frame: int


static func create_multiplayer_game(player_side: int) -> PongGame:
	var game: PongGame = (load("res://src/pong/pong_game.tscn") as PackedScene).instance() as PongGame
	game.connect("game_won_by", game, "popup_end_game", [player_side])

	if OS.has_touchscreen_ui_hint():
		match UserPreferences.mobile_input:
			UserPreferences.MobileInput.ONE_HAND:
				game.add_child(MobileOneHandInput.new().configure(player_side))
			UserPreferences.MobileInput.TWO_HAND:
				game.add_child(MobileTwoHandInput.new().configure(player_side))

	game.players = [null, null]
	game.players[player_side] = Player.new(
									Netcode.LocalPlayer.new(),
									Game_Input.new(player_side),
									game.get_node("LeftPaddle" if player_side == Globals.Side.LEFT else "RightPaddle"))
	game.players[Globals.opposite_side(player_side)] = Player.new(
									Netcode.RemotePlayer.new(),
									Local_Input.new(),
									game.get_node("LeftPaddle" if Globals.opposite_side(player_side) == Globals.Side.LEFT else "RightPaddle"))

	game.get_node("LeftPaddle").add_child(DifferentialBounce.create())#UserPreferences.get_user_paddle_bounce())
	game.get_node("RightPaddle").add_child(DifferentialBounce.create())#UserPreferences.get_user_paddle_bounce())

	return game


#static func create(game_type: int, player_side: int = Globals.Side.LEFT) -> PongGame:
#	var game = (load("res://src/pong/pong_game.tscn") as PackedScene).instance() as PongGame
#
#	if game_type == GameType.LOCAL_MULTIPLAYER:
#		game.connect("game_won_by", game, "popup_end_multiplayer_game")
#	else:
#		game.connect("game_won_by", game, "popup_end_game", [player_side])
#
#	if OS.has_touchscreen_ui_hint():
#		if game_type == GameType.LOCAL_MULTIPLAYER:
#			game.add_child(MobileOneHandInput.new().configure(Globals.Side.LEFT))
#			game.add_child(MobileOneHandInput.new().configure(Globals.Side.RIGHT))
#		else:
#			match UserPreferences.mobile_input:
#				UserPreferences.MobileInput.ONE_HAND:
#					game.add_child(MobileOneHandInput.new().configure(player_side))
#				UserPreferences.MobileInput.TWO_HAND:
#					game.add_child(MobileTwoHandInput.new().configure(player_side))
#
#	var left_player := {}
#	var right_player := {}
#
#	left_player.paddle = game.get_node("LeftPaddle")
#	right_player.paddle = game.get_node("RightPaddle")
#
#	match game_type:
#		GameType.LOCAL_AI:
#			left_player.paddle.add_child(UserPreferences.get_user_paddle_bounce())
#			right_player.paddle.add_child(DifferentialBounce.create())
#			left_player.input = Game_Input.new(Globals.Side.LEFT)
#			right_player.input = Remote_Input.new()
#			left_player.net = Netcode.LocalPlayer.new()
#			right_player.net = Netcode.LocalPlayer.new()
#
#	game.players.append(Player.new(left_player.net, left_player.input, left_player.paddle))
#	game.players.append(Player.new(right_player.net, right_player.input, right_player.paddle))
#
#	Netcode.create_players(left_player.net, right_player.net)
#	return game


func _ready():
	ball.connect("collided_left_goal", ball, "restart_left", [center])
	ball.connect("collided_right_goal", ball, "restart_right", [center])

	ball.restart(Vector2.RIGHT, center)


func _physics_process(delta: float):
	var rollback_frame := current_frame

	for player in players:
		if player.net is Netcode.LocalPlayer:
			player.net.send_input(current_frame, player.input.to_data())
#			print(current_frame, " - ", player.input.to_data())
		else:
			rollback_frame = player.net.receive_input(current_frame)
			if player.net.has_max_rollback_exceeded(current_frame):
				return

	if rollback_frame < current_frame:
#		print("ROLLBACK to ", rollback_frame)
		reset_game_state(Netcode.get_game_state(rollback_frame - current_frame))

	while rollback_frame <= current_frame:
		Netcode.set_game_state(rollback_frame - current_frame, create_game_state(rollback_frame, delta))
		for player in players:
			player.paddle.handle_input(player.net.get_input(rollback_frame), delta)
			player.paddle.physics_process(delta)
		ball.physics_process(delta)
		rollback_frame += 1

	var result := Netcode.receive_game_state()
	if not result.state_match:
		print("Invalid game state!")
		print("Local  State: ", result.local_game_state)
		print("Remote State: ", result.remote_game_state)
		pass
	if Netcode.game_state_ready_to_send():
		Netcode.send_game_state()

	current_frame += 1


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


func create_game_state(frame: int, delta: float) -> PoolByteArray:
	var state := {"frame": frame,
					"delta": delta,
					"ball.position": ball.position,
					"ball.velocity": ball.velocity,
					"ball.bonus_velocity": ball.bonus_velocity,
					"ball.spin": ball.spin,
					"players[0].paddle.position": players[0].paddle.position,
					"players[0].paddle.charge": players[0].paddle.charge,
					"players[1].paddle.position": players[1].paddle.position,
					"players[1].paddle.charge": players[1].paddle.charge,
					"left_score": left_score,
					"right_score": right_score,
				}
	return var2bytes(state)


func reset_game_state(game_state: PoolByteArray) -> void:
	var dict = bytes2var(game_state)
	ball.position = dict["ball.position"]
	ball.velocity = dict["ball.velocity"]
	ball.bonus_velocity = dict["ball.bonus_velocity"]
	ball.spin = dict["ball.spin"]
	players[0].paddle.position = dict["players[0].paddle.position"]
	players[0].paddle.charge = dict["players[0].paddle.charge"]
	players[1].paddle.position = dict["players[1].paddle.position"]
	players[1].paddle.charge = dict["players[1].paddle.charge"]
	left_score = dict["left_score"]
	right_score = dict["right_score"]


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
