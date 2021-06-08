class_name MobileInput
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

var _touch_position := Vector2.ZERO


func _ready():
	Input.action_release(player + "_move_to")
	Input.action_release(player + "_charge")


func _input(event: InputEvent):
	if event is InputEventScreenDrag:
		_drag_to_action(event as InputEventScreenDrag)
	elif event is InputEventScreenTouch:
		_touch_to_action(event as InputEventScreenTouch)


func _drag_to_action(_drag: InputEventScreenDrag):
	pass


func _touch_to_action(_touch: InputEventScreenTouch):
	pass


func _is_control_side(x_position: float):
	match side:
		Globals.Side.LEFT:
			return x_position < _center.x
		Globals.Side.RIGHT:
			return x_position > _center.x


func set_side(new_side: int):
	self.side = new_side


func set_player(new_player: String):
	self.player = new_player
