extends Node2D
class_name PongGame

signal left_scored()
signal right_scored()

onready var _left_paddle := $LeftPaddle as Paddle
onready var _right_paddle := $RightPaddle as Paddle

onready var _left_goal := $LeftGoal as PhysicsBody2D
onready var _right_goal := $RightGoal as PhysicsBody2D

onready var _ball := $Ball as Node2D

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER, SERVER}
var _game_type: int = GameType.NONE

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
		var mobile_input
		match UserPreferences.mobile_input:
			Globals.MobileInput.ONE_HAND:
				mobile_input = (load("res://game/scenes/mobile_inputs/mobile_input_one_hand.tscn") as PackedScene).instance()
			Globals.MobileInput.TWO_HANDS:
				mobile_input = (load("res://game/scenes/mobile_inputs/mobile_input_two_hands.tscn") as PackedScene).instance()

		if Network.is_network_game():
			mobile_input.set_side(player_side)

		add_child(mobile_input)

	match _game_type:
		GameType.SERVER:
			_configure_game_as_server()
		GameType.NETWORK_MULTIPLAYER:
			_configure_game_as_network_multiplayer()
		GameType.LOCAL_MULTIPLAYER:
			_configure_game_as_local_multiplayer()
		GameType.LOCAL_AI:
			_configure_game_as_local_ai()


func _configure_game_as_server():
	_left_paddle.player_type = Paddle.PlayerType.NETWORK
	_left_paddle.set_collision_layer(0)
	_left_paddle.set_collision_mask(0)
	_left_goal.set_collision_layer(0)
	_left_goal.set_collision_mask(0)
	_right_paddle.player_type = Paddle.PlayerType.NETWORK
	_right_paddle.set_collision_layer(0)
	_right_paddle.set_collision_mask(0)
	_right_goal.set_collision_layer(0)
	_right_goal.set_collision_mask(0)


func _configure_game_as_network_multiplayer():
	match player_side:
		Globals.Side.LEFT:
			_left_paddle.player_type = Paddle.PlayerType.HUMAN_01
			_right_paddle.player_type = Paddle.PlayerType.NETWORK
			_right_paddle.set_collision_layer(0)
			_right_paddle.set_collision_mask(0)
			_right_goal.set_collision_layer(0)
			_right_goal.set_collision_mask(0)
		Globals.Side.RIGHT:
			_right_paddle.player_type = Paddle.PlayerType.HUMAN_01
			_left_paddle.player_type = Paddle.PlayerType.NETWORK
			_left_paddle.set_collision_layer(0)
			_left_paddle.set_collision_mask(0)
			_left_goal.set_collision_layer(0)
			_left_goal.set_collision_mask(0)


func _configure_game_as_local_multiplayer():
	_left_paddle.player_type = Paddle.PlayerType.HUMAN_01
	_right_paddle.player_type = Paddle.PlayerType.HUMAN_02


func _configure_game_as_local_ai():
	_left_paddle.player_type = Paddle.PlayerType.HUMAN_01
	_right_paddle.player_type = Paddle.PlayerType.AI


func _process(_delta: float):
	if _game_type == GameType.NETWORK_MULTIPLAYER:
		match player_side:
			Globals.Side.LEFT:
				_left_paddle.rpc_unreliable("set_position", _left_paddle.position)
			Globals.Side.RIGHT:
				_right_paddle.rpc_unreliable("set_position", _right_paddle.position)


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
		_end_game()
	elif _right_score == goals_to_win:
		match player_side:
			Globals.Side.LEFT:
				_popup_end_game(false, Globals.Side.RIGHT)
			Globals.Side.RIGHT:
				_popup_end_game(true, Globals.Side.RIGHT)
		_end_game()


func _end_game():
	get_tree().set_pause(true)


func _popup_end_game(won: bool, side: int):
	var end_game_popup : PopupPanel

	if _game_type == GameType.LOCAL_MULTIPLAYER:
		end_game_popup = EndGamePopup.create_popup_with_side_victory(side)
	else:
		end_game_popup = EndGamePopup.create_popup(won)

	get_tree().get_root().add_child(end_game_popup)

	end_game_popup.connect("hide", self, "_on_EndGamePopup_hide")
	end_game_popup.popup()


func _on_EndGamePopup_hide():
	get_tree().set_pause(false)

	var main_menu := (load("res://game/scenes/main_menu.tscn") as PackedScene).instance()

	get_tree().get_root().add_child(main_menu)
	get_tree().get_root().remove_child(self)

	self.queue_free()
