extends Node2D
class_name AI

var ball: Ball
var enemy_paddle: Paddle
var my_paddle: Paddle

var player_number: String

func configure_ai(ball_: Ball, enemy_paddle_: Paddle, my_paddle_: Paddle):
	ball = ball_
	enemy_paddle = enemy_paddle_
	my_paddle = my_paddle_

	player_number = "player_01" if Paddle.PlayerType.AI_01 == my_paddle.player_type else "player_02"


func _physics_process(_delta: float):
	if ball.position.y < my_paddle.position.y:
		Input.action_press(player_number + "_up", 1.0)
		Input.action_release(player_number + "_down")
	else:
		Input.action_press(player_number + "_down", 1.0)
		Input.action_release(player_number + "_up")
