extends KinematicBody2D

signal scored(player)

export(float) var radius
export(float) var bounceAccel
export(Vector2) var startVelocity

var velocity = Vector2()

func _ready():
	_reset(Vector2.RIGHT)

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.white)

# warning-ignore:unused_argument
func _physics_process(delta):
# warning-ignore:return_value_discarded
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
		if collision.collider.is_in_group("paddles"):
			velocity *= bounceAccel
		elif collision.collider.name == "LeftGoal":
			_reset(Vector2.LEFT)
			emit_signal("scored", 2)
		elif collision.collider.name == "RightGoal":
			_reset(Vector2.RIGHT)
			emit_signal("scored", 1)

func _reset(side: Vector2):
	position = Vector2(960, 540);
	velocity = startVelocity * side
