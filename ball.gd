extends KinematicBody2D

signal right_scored()
signal left_scored()

export(float) var radius

export(float) var bounce_accel
export(Vector2) var start_velocity

export(float) var bonus_velocity_minimum
export(float) var bonus_velocity_range

export(float) var angular_y_velocity
export(float) var maximum_x_velocity

var _velocity = Vector2()
var _bonus_velocity = 1.0

var _spin = 0.0

onready var _center = Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)

func _ready():
	_reset(Vector2.RIGHT)

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.white)

func _process(delta):
	if _spin:
		_velocity.y += _spin * delta * 3
		_spin -= _spin * delta * 3

func _physics_process(delta):
	var collision = move_and_collide(_velocity * _bonus_velocity * delta)
	if collision:
		if collision.collider.is_in_group("paddles"):
			_collide_paddles(collision)
		elif collision.collider.is_in_group("walls"):
			_collide_walls(collision)
		elif collision.collider.name == "LeftGoal":
			_collide_left_goal()
		elif collision.collider.name == "RightGoal":
			_collide_right_goal()

func _collide_paddles(collision):
	match collision.collider.paddleType:
		Globals.PaddleType.DIFFERENTIAL:
			_bonus_velocity = bonus_velocity_minimum + abs(collision.collider.velocity.y) * 0.0015
			if collision.collider.velocity.y:
				_spin = -collision.collider.velocity.y * 3
				_velocity.y = collision.collider.velocity.y * 1.5
			else:
				_spin = -_velocity.y * 1.5
			_velocity = _velocity.bounce(collision.normal)
		Globals.PaddleType.ANGULAR:
			var collision_relative_position = \
				collision.position.y - collision.collider.position.y
			var percent_distance_from_center = \
				collision_relative_position / collision.collider_shape.shape.extents.x

			_bonus_velocity = bonus_velocity_minimum + bonus_velocity_range * abs(percent_distance_from_center)

			_velocity.y = percent_distance_from_center * angular_y_velocity
			_velocity = _velocity.bounce(collision.normal)
			_spin = 0.0
		Globals.PaddleType.GEOMETRIC:
			_velocity = _velocity.bounce(collision.normal)
			_bonus_velocity = 1.0
			_spin = 0.0

	_velocity *= bounce_accel
	_velocity.x = min(_velocity.x, maximum_x_velocity)

	_bonus_velocity += collision.collider.charge
	_spin *= 1.0 + collision.collider.charge

func _collide_walls(collision):
	_velocity = _velocity.bounce(collision.normal)
	_spin = -_spin

func _collide_left_goal():
	_reset(Vector2.LEFT)
	emit_signal("right_scored")

func _collide_right_goal():
	_reset(Vector2.RIGHT)
	emit_signal("left_scored")

func _reset(side: Vector2):
	position = _center;
	
	side.y = rand_range(-1.25, 1.25)
	_velocity = start_velocity * side.normalized()
	_bonus_velocity = 1.0
	_spin = 0.0
