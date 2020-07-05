extends Node2D

## Mobile Input Scheme 01
#
# This scheme relies on multi-touch, as both left
#  and right side may be pressed simultaneously.
#
# Left side of screen controls the Paddle movement.
# - Touching the upper left side moves the Paddle up.
# - Touching the lower left side moves the Paddle down.
#
# Right side of the screen control the charge.
# - Touching the right side will charge the Paddle.
#

func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		_drag_to_action(event as InputEventScreenDrag)
	elif event is InputEventScreenTouch:
		_touch_to_action(event as InputEventScreenTouch)


func _drag_to_action(drag: InputEventScreenDrag):
	if drag.position.x < 960:
		if drag.position.y < 540:
			Input.action_release("player_01_down")
			Input.action_press("player_01_up")
		else:
			Input.action_release("player_01_up")
			Input.action_press("player_01_down")


func _touch_to_action(touch: InputEventScreenTouch):
	if touch.is_pressed():
		if touch.position.x > 960:
			Input.action_press("player_01_charge")
		else:
			if touch.position.y < 540:
				Input.action_press("player_01_up")
			else:
				Input.action_press("player_01_down")
	else:
		if touch.position.x > 960:
			Input.action_release("player_01_charge")
		else:
			Input.action_release("player_01_up")
			Input.action_release("player_01_down")