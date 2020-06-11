extends KinematicBody2D

export(int) var speed
var velocity = Vector2()

# warning-ignore:unused_argument
func _physics_process(delta):
	if Input.is_action_pressed("ui_up"):
		velocity.y = -speed
	elif Input.is_action_pressed("ui_down"):
		velocity.y = speed
	else:
		velocity = Vector2.ZERO
	
# warning-ignore:return_value_discarded
	move_and_slide(velocity)
