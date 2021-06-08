extends Control

var actions := ["_up", "_down"]

var left := 0
var right := 1


func _ready():
	randomize()

	Input.action_press("player_01" + actions[left])
	Input.action_press("player_02" + actions[right])

	connect("tree_exiting", self, "_release_inputs")


func _release_inputs():
	Input.action_release("player_01_up")
	Input.action_release("player_01_down")
	Input.action_release("player_02_up")
	Input.action_release("player_02_down")


func _on_Timer_timeout():
	var ball := Ball.create()
	add_child(ball)

	ball.restart(rect_size / 2, Vector2.LEFT if randf() < 0.5 else Vector2.RIGHT)
	ball.connect("collided_goal", ball, "free_on_collision")


func _on_LeftDemoInput_timeout():
	Input.action_release("player_01" + actions[left])
	left = (left + 1) % 2
	Input.action_press("player_01" + actions[left])


func _on_RightDemoInput_timeout():
	Input.action_release("player_02" + actions[right])
	right = (right + 1) % 2
	Input.action_press("player_02" + actions[right])
