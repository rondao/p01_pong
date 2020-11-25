extends KinematicBody2D
class_name Ball

signal collided_goal()
signal collided_paddle()

export(PackedScene) var CollisionSfx: PackedScene

export(float) var radius: float

export(float) var bounce_accel: float
export(Vector2) var start_velocity: Vector2

export(float) var bonus_velocity_minimum: float
export(float) var bonus_velocity_range: float

export(float) var angular_y_velocity: float
export(float) var maximum_x_velocity: float

var _velocity := Vector2()
var _bonus_velocity := 1.0
var latency_speed_adjustment := 1.0

var _spin := 0.0

onready var _trail := $Trail as BallTrail
var _trail_enabled := false

onready var _audio_hit := $AudioHit as AudioStreamPlayer2D
onready var _audio_power_hit := $AudioPowerHit as AudioStreamPlayer2D
onready var _audio_wall_bounce := $AudioWallBounce as AudioStreamPlayer2D

onready var _animation := $Animation as AnimationPlayer

const BALL_SPAWNING_ANIMATION := "ball_spawn"

onready var _center := Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)


func _draw():
	if _trail_enabled:
		draw_circle(Vector2.ZERO, radius + 2, Color.red)
	draw_circle(Vector2.ZERO, radius, Color.white)


func _process(delta: float):
	if _spin:
		_velocity.y += _spin * latency_speed_adjustment * delta * 3
		_spin -= _spin * latency_speed_adjustment * delta * 3


func _physics_process(delta: float):
	var collision := move_and_collide(_velocity * _bonus_velocity * latency_speed_adjustment * delta)
	if collision:
		var collider := collision.collider as Node
		if collider.is_in_group("paddles"):
			_collide_paddles(collision)
			if collider.name == "LeftPaddle":
				emit_signal("collided_paddle", Globals.Side.LEFT)
			elif collider.name == "RightPaddle":
				emit_signal("collided_paddle", Globals.Side.RIGHT)
		elif collider.is_in_group("walls"):
			_collide_walls(collision)
			_spawn_collision_sfx()
			_audio_wall_bounce.play()
		elif collider.name == "LeftGoal":
			_collided_goal(Globals.Side.LEFT)
		elif collider.name == "RightGoal":
			_collided_goal(Globals.Side.RIGHT)


func restart(side: Vector2):
	position = _center;
	
	side.y = rand_range(-1.25, 1.25)
	_velocity = start_velocity * side.normalized()
	_bonus_velocity = 1.0
	_spin = 0.0

	_hide_trail()
	_animation.play(BALL_SPAWNING_ANIMATION)


func _collided_goal(side: int):
	GameServer.send_collided_goal(side)
	emit_signal("collided_goal", side)


func apply_collision(_new_position: Vector2, _new_velocity: Vector2, _new_bonus_velocity: float, _new_spin: float):
	position = _new_position
	_velocity = _new_velocity
	_bonus_velocity = _new_bonus_velocity
	_spin = _new_spin
	latency_speed_adjustment = 1

	_after_paddle_collision()


func _collide_paddles(collision: KinematicCollision2D):
	var collider := collision.collider as Paddle
	match collider.paddle_type:
		Globals.PaddleType.DIFFERENTIAL:
			_bonus_velocity = bonus_velocity_minimum + abs(collider.velocity.y) * 0.001
			if collider.velocity.y:
				_spin = -collider.velocity.y * 1.75
				_velocity.y = collider.velocity.y * 1.5
			else:
				_spin = -_velocity.y * 1.5
			_velocity = _velocity.bounce(collision.normal)
		Globals.PaddleType.ANGULAR:
			var collision_relative_position := \
				collision.position.y - collider.position.y
			var percent_distance_from_center := \
				collision_relative_position / ((collision.collider_shape as CollisionShape2D).shape as RectangleShape2D).extents.x

			_bonus_velocity = bonus_velocity_minimum + bonus_velocity_range * abs(percent_distance_from_center)

			_velocity.y = percent_distance_from_center * angular_y_velocity
			_velocity = _velocity.bounce(collision.normal)
			_spin = 0.0
		Globals.PaddleType.GEOMETRIC:
			_velocity = _velocity.bounce(collision.normal)
			_bonus_velocity = 1.0
			_spin = 0.0

	_velocity *= bounce_accel
	_velocity.x = sign(_velocity.x) * min(abs(_velocity.x), maximum_x_velocity)

	_bonus_velocity += collider.charge
	_spin *= 1.0 + collider.charge

	GameServer.send_ball_collided(position, _velocity, _bonus_velocity, _spin)
	_after_paddle_collision()


func _after_paddle_collision():
	if _bonus_velocity > 1.0:
		_show_trail()
		_audio_power_hit.play()
	else:
		_hide_trail()
		_audio_hit.play()
	_spawn_collision_sfx()


func _collide_walls(collision: KinematicCollision2D):
	_velocity = _velocity.bounce(collision.normal)
	_spin = -_spin


func _show_trail():
	_trail_enabled = true
	_trail.enable()
	update()


func _hide_trail():
	_trail_enabled = false
	_trail.disable()
	update()


func _spawn_collision_sfx():
	var sfx := CollisionSfx.instance() as Node2D
	sfx.position = position
	get_parent().add_child(sfx)

