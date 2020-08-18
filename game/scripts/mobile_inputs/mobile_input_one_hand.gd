extends Node2D

## Mobile Input Scheme one hand
#
# This scheme uses only one screen side,
#  required for one device multiplayer.
#
# Paddle will move to touch y-position.
# Dragging in X direction activates charge.
#

onready var _center := Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

export(String) var player := "player_01"
export(Globals.Side) var side: int = Globals.Side.LEFT

const DRAG_FOR_CHARGE := 150
var _touch_position := Vector2.ZERO


func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		_drag_to_action(event as InputEventScreenDrag)
	elif event is InputEventScreenTouch:
		_touch_to_action(event as InputEventScreenTouch)


func _drag_to_action(drag: InputEventScreenDrag):
	if _is_correct_side(drag.position.x):
		Input.action_press(player + "_move_to", drag.position.y / get_viewport().size.y)

		if abs(drag.position.x - _touch_position.x) > DRAG_FOR_CHARGE:
			Input.action_press(player + "_charge")


func _touch_to_action(touch: InputEventScreenTouch):
	if _is_correct_side(touch.position.x):
		if touch.is_pressed():
			_touch_position = touch.position
			Input.action_press(player + "_move_to", touch.position.y / get_viewport().size.y)
		else:
			Input.action_release(player + "_move_to")
			Input.action_release(player + "_charge")


func _is_correct_side(x_position: float):
	match side:
		Globals.Side.LEFT:
			return x_position < _center.x
		Globals.Side.RIGHT:
			return x_position > _center.x


func set_side(side: int):
	self.side = side
