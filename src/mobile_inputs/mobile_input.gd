extends Node2D
class_name MobileInput

## Mobile Input Scheme one hand
#
# This scheme uses only one screen side,
#  required for one device multiplayer.
#
# Paddle will move to touch y-position.
# Dragging in X direction activates charge.
#

onready var center := Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

var side: int = Globals.Side.NONE

var touch_position := Vector2.ZERO


func _ready():
	Input.action_release(str(side) + "_move_to")
	Input.action_release(str(side) + "_charge")


func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		drag_to_action(event as InputEventScreenDrag)
	elif event is InputEventScreenTouch:
		touch_to_action(event as InputEventScreenTouch)


func configure(side_: int) -> MobileInput:
	side = side_
	return self


func drag_to_action(_drag: InputEventScreenDrag):
	pass


func touch_to_action(_touch: InputEventScreenTouch):
	pass


func is_on_player_side(x_position: float):
	match side:
		Globals.Side.LEFT:
			return x_position < center.x
		Globals.Side.RIGHT:
			return x_position > center.x
