extends Control

var actions := ["_up", "_down"]

var left_input := 0
var right_input := 1

var left_data_input := Game_Input.new(Globals.Side.LEFT)
var right_data_input := Game_Input.new(Globals.Side.RIGHT)

onready var left_paddle := $LeftPaddle as Paddle
onready var right_paddle := $RightPaddle as Paddle


func _ready():
	randomize()

	Input.action_press(str(Globals.Side.LEFT) + actions[left_input])
	Input.action_press(str(Globals.Side.RIGHT) + actions[right_input])

	connect("tree_exiting", self, "release_inputs")


func _on_Timer_timeout():
	var ball := Ball.create()
	add_child(ball)

	ball.restart(Vector2.LEFT if randf() < 0.5 else Vector2.RIGHT, rect_size / 2)
	ball.connect("collided_left_goal", ball, "queue_free")
	ball.connect("collided_right_goal", ball, "queue_free")


func _physics_process(delta: float):
	left_paddle.handle_input(left_data_input.to_data(), delta)
	right_paddle.handle_input(right_data_input.to_data(), delta)


func _on_LeftDemoInput_timeout():
	Input.action_release(str(Globals.Side.LEFT) + actions[left_input])
	left_input = (left_input + 1) % 2
	Input.action_press(str(Globals.Side.LEFT) + actions[left_input])


func _on_RightDemoInput_timeout():
	Input.action_release(str(Globals.Side.RIGHT) + actions[right_input])
	right_input = (right_input + 1) % 2
	Input.action_press(str(Globals.Side.RIGHT) + actions[right_input])


func release_inputs():
	Input.action_release(str(Globals.Side.LEFT) + "_up")
	Input.action_release(str(Globals.Side.LEFT) + "_down")
	Input.action_release(str(Globals.Side.RIGHT) + "_up")
	Input.action_release(str(Globals.Side.RIGHT) + "_down")
