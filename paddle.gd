extends KinematicBody2D

enum Player {HUMAN, NONE}
export(Player) var player

export(int) var speed
var velocity = Vector2()

# warning-ignore:unused_argument
func _physics_process(delta):
	match player:
		Player.HUMAN:
			_handle_input()
	
# warning-ignore:return_value_discarded
	move_and_slide(velocity)

func _handle_input():
	if Input.is_action_pressed("ui_up"):
		velocity.y = -speed
	elif Input.is_action_pressed("ui_down"):
		velocity.y = speed
	else:
		velocity = Vector2.ZERO
