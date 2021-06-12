extends Node2D
class_name AI

var ball: Ball
var my_paddle: Paddle


func configure_ai(ball_: Ball, my_paddle_: Paddle) -> AI:
	ball = ball_
	my_paddle = my_paddle_
	return self


func _physics_process(_delta: float) -> void:
	if ball.position.y < my_paddle.position.y:
		Input.action_press(player_number + "_up", 1.0)
		Input.action_release(player_number + "_down")
	else:
		Input.action_press(player_number + "_down", 1.0)
		Input.action_release(player_number + "_up")
