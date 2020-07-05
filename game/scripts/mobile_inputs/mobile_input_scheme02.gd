extends Node2D

## Mobile Input Scheme 02
#
# This scheme relies on multi-touch, as both left
#  and right side may be pressed simultaneously.
#
# Left side of screen controls the Paddle movement.
# - Paddle will move to touch y-position
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
		Input.action_press("player_01_move_to", drag.position.y / 1080)


func _touch_to_action(touch: InputEventScreenTouch):
	if touch.is_pressed():
		if touch.position.x < 960:
			Input.action_press("player_01_move_to", touch.position.y / 1080)
		else:
			Input.action_press("player_01_charge")
	else:
		if touch.position.x < 960:
			Input.action_release("player_01_move_to")
		else:
			Input.action_release("player_01_charge")
