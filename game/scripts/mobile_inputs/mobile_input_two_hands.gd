extends Node2D

## Mobile Input Scheme two hands
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

onready var _center := Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

export(String) var player := "player_01"
export(Globals.Side) var side: int = Globals.Side.LEFT


func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		_drag_to_action(event as InputEventScreenDrag)
	elif event is InputEventScreenTouch:
		_touch_to_action(event as InputEventScreenTouch)


func _drag_to_action(drag: InputEventScreenDrag):
	if _is_control_side(drag.position.x):
		Input.action_press(player + "_move_to", drag.position.y / get_viewport().size.y)


func _touch_to_action(touch: InputEventScreenTouch):
	if touch.is_pressed():
		if _is_control_side(touch.position.x):
			Input.action_press(player + "_move_to", touch.position.y / get_viewport().size.y)
		else:
			Input.action_press(player + "_charge")
	else:
		if _is_control_side(touch.position.x):
			Input.action_release(player + "_move_to")
		else:
			Input.action_release(player + "_charge")


func _is_control_side(x_position: float):
	match side:
		Globals.Side.LEFT:
			return x_position < _center.x
		Globals.Side.RIGHT:
			return x_position > _center.x


func set_side(side: int):
	self.side = side
