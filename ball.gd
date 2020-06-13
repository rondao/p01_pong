extends KinematicBody2D

signal right_scored()
signal left_scored()

export(float) var radius
export(float) var bounceAccel
export(Vector2) var startVelocity

var _velocity = Vector2()

onready var _center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

func _ready():
	_reset(Vector2.RIGHT)

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.white)

# warning-ignore:unused_argument
func _physics_process(delta):
# warning-ignore:return_value_discarded
	var collision = move_and_collide(_velocity * delta)
	if collision:
		_velocity = _velocity.bounce(collision.normal)
		if collision.collider.is_in_group("paddles"):
			_velocity *= bounceAccel
		elif collision.collider.name == "LeftGoal":
			_reset(Vector2.LEFT)
			emit_signal("right_scored")
		elif collision.collider.name == "RightGoal":
			_reset(Vector2.RIGHT)
			emit_signal("left_scored")

func _reset(side: Vector2):
	position = _center;
	
	side.y = rand_range(-1.25, 1.25)
	_velocity = startVelocity * side.normalized()
