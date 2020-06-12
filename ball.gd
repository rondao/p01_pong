extends KinematicBody2D

signal scored(player)

export(float) var radius
export(float) var bounceAccel
export(Vector2) var startVelocity

var _velocity = Vector2()
var _rng = RandomNumberGenerator.new()

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
			emit_signal("scored", 2)
		elif collision.collider.name == "RightGoal":
			_reset(Vector2.RIGHT)
			emit_signal("scored", 1)

func _reset(side: Vector2):
	position = Vector2(OS.window_size.x / 2, OS.window_size.y / 2);
	
	side.y = _rng.randf_range(-1.25, 1.25)
	_velocity = startVelocity * side
