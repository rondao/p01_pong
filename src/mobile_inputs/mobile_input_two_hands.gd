extends MobileInput
class_name MobileTwoHandInput

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


static func create() -> MobileTwoHandInput:
	return (load("res://src/mobile_inputs/mobile_input_two_hand.tscn") as PackedScene).instance() as MobileTwoHandInput


func drag_to_action(drag: InputEventScreenDrag):
	if is_on_player_side(drag.position.x):
		Input.action_press(player + "_move_to", drag.position.y)


func touch_to_action(touch: InputEventScreenTouch):
	if touch.is_pressed():
		if is_on_player_side(touch.position.x):
			Input.action_press(player + "_move_to", touch.position.y)
		else:
			Input.action_press(player + "_charge")
	else:
		if is_on_player_side(touch.position.x):
			Input.action_release(player + "_move_to")
		else:
			Input.action_release(player + "_charge")
