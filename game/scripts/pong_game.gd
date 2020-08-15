extends Node2D
class_name PongGame

export(PackedScene) var MobileInputOneHand: PackedScene
export(PackedScene) var MobileInputTwoHands: PackedScene

onready var _left_paddle := $LeftPaddle as Paddle
onready var _right_paddle := $RightPaddle as Paddle

enum GameType {NONE, LOCAL_AI, LOCAL_MULTIPLAYER, NETWORK_MULTIPLAYER, SERVER}
var game_type: int = GameType.NONE

var network_side: int

func _ready():
	if OS.has_touchscreen_ui_hint():
		match UserPreferences.mobile_input:
			Globals.MobileInput.ONE_HAND:
				add_child(MobileInputOneHand.instance())
			Globals.MobileInput.TWO_HANDS:
				add_child(MobileInputTwoHands.instance())

	match game_type:
		GameType.SERVER:
			_left_paddle.set_network_master(get_tree().get_network_connected_peers()[0])
			_left_paddle.player_type = Paddle.PlayerType.NETWORK
			_right_paddle.set_network_master(get_tree().get_network_connected_peers()[1])
			_right_paddle.player_type = Paddle.PlayerType.NETWORK
		GameType.NETWORK_MULTIPLAYER:
			match network_side:
				Globals.Side.LEFT:
					_left_paddle.set_network_master(get_tree().get_network_unique_id())
					_left_paddle.player_type = Paddle.PlayerType.HUMAN_01
					_right_paddle.set_network_master(get_tree().get_network_connected_peers()[1])
					_right_paddle.player_type = Paddle.PlayerType.NETWORK
				Globals.Side.RIGHT:
					_right_paddle.set_network_master(get_tree().get_network_unique_id())
					_right_paddle.player_type = Paddle.PlayerType.HUMAN_01
					_left_paddle.set_network_master(get_tree().get_network_connected_peers()[1])
					_left_paddle.player_type = Paddle.PlayerType.NETWORK
		GameType.LOCAL_MULTIPLAYER:
			_left_paddle.player_type = Paddle.PlayerType.HUMAN_01
			_right_paddle.player_type = Paddle.PlayerType.HUMAN_02
		GameType.LOCAL_AI:
			_left_paddle.player_type = Paddle.PlayerType.HUMAN_01
			_right_paddle.player_type = Paddle.PlayerType.AI


func _process(_delta: float):
	if game_type == GameType.NETWORK_MULTIPLAYER:
		if _left_paddle.is_network_master():
			_left_paddle.rpc_unreliable("set_position", _left_paddle.position)
		if _right_paddle.is_network_master():
			_right_paddle.rpc_unreliable("set_position", _right_paddle.position)

