extends Local_Input
class_name AI_Input

var ball: Ball
var my_paddle: Paddle


func _init(ball_: Ball, my_paddle_: Paddle):
	ball = ball_
	my_paddle = my_paddle_


func to_data() -> int:
	if ball.position.y < my_paddle.position.y:
		return Globals.GameInput.UP
	else:
		return Globals.GameInput.DOWN
