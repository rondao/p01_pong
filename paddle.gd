extends KinematicBody2D

enum Player {HUMAN_01, HUMAN_02, NONE}
export(Player) var player

export(int) var speed
var velocity = Vector2()

# warning-ignore:unused_argument
func _physics_process(delta):
	match player:
		Player.HUMAN_01:
			_handle_input("player_01_up", "player_01_down")
		Player.HUMAN_02:
			_handle_input("player_02_up", "player_02_down")
	
# warning-ignore:return_value_discarded
	move_and_slide(velocity)

func _handle_input(up_action, down_action):
	if Input.is_action_pressed(up_action):
		velocity.y = -speed
	elif Input.is_action_pressed(down_action):
		velocity.y = speed
	else:
		velocity = Vector2.ZERO
