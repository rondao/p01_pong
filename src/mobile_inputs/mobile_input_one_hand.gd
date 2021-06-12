extends MobileInput
class_name MobileOneHandInput

## Mobile Input Scheme one hand
#
# This scheme uses only one screen side,
#  required for one device multiplayer.
#
# Paddle will move to touch y-position.
# Dragging in X direction activates charge.
#

const DRAG_FOR_CHARGE := 150


static func create() -> MobileOneHandInput:
	return (load("res://src/mobile_inputs/mobile_input_one_hand.tscn") as PackedScene).instance() as MobileOneHandInput


func drag_to_action(drag: InputEventScreenDrag):
	if is_on_player_side(drag.position.x):
		Input.action_press(player + "_move_to", drag.position.y)

		if abs(drag.position.x - touch_position.x) > DRAG_FOR_CHARGE:
			Input.action_press(player + "_charge")


func touch_to_action(touch: InputEventScreenTouch):
	if is_on_player_side(touch.position.x):
		if touch.is_pressed():
			touch_position = touch.position
			Input.action_press(player + "_move_to", touch.position.y)
		else:
			Input.action_release(player + "_move_to")
			Input.action_release(player + "_charge")
