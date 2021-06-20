extends Local_Input
class_name Game_Input

var player_side: int


func _init(player_side_: int):
	player_side = player_side_


func to_data() -> int:
	var input = Globals.GameInput.NONE

	if Input.is_action_pressed(str(player_side) + "_up"):
		input |= Globals.GameInput.UP
	elif Input.is_action_pressed(str(player_side) + "_down"):
		input |= Globals.GameInput.DOWN
	else:
		input = Globals.GameInput.NONE

	if Input.is_action_pressed(str(player_side) + "_charge"):
		input |= Globals.GameInput.CHARGE

	return input
