extends Timer

var actions := ["_up", "_down"]

var left := 0
var right := 1


func _ready():
	Input.action_press("player_01" + actions[left])
	Input.action_press("player_02" + actions[right])


func _on_LeftDemoInput_timeout():
	Input.action_release("player_01" + actions[left])
	left = (left + 1) % 2
	Input.action_press("player_01" + actions[left])


func _on_RightDemoInput_timeout():
	Input.action_release("player_02" + actions[right])
	right = (right + 1) % 2
	Input.action_press("player_02" + actions[right])
