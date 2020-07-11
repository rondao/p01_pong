extends KinematicBody2D

signal right_scored()
signal left_scored()

export(PackedScene) var CollisionSfx: PackedScene
export(PackedScene) var GoalSfx: PackedScene

export(float) var radius: float

export(float) var bounce_accel: float
export(Vector2) var start_velocity: Vector2

export(float) var bonus_velocity_minimum: float
export(float) var bonus_velocity_range: float

export(float) var angular_y_velocity: float
export(float) var maximum_x_velocity: float

var _velocity := Vector2()
var _bonus_velocity := 1.0

var _spin := 0.0

onready var _trail := $Trail as BallTrail
var _trail_enabled := false

onready var _audio_hit := $AudioHit as AudioStreamPlayer2D
onready var _audio_power_hit := $AudioPowerHit as AudioStreamPlayer2D
onready var _audio_wall_bounce := $AudioWallBounce as AudioStreamPlayer2D
onready var _audio_goal := $AudioGoal as AudioStreamPlayer2D

onready var _center := Vector2(get_viewport().size.x / 2, get_viewport().size.y / 2)


func _ready():
	_reset(Vector2.RIGHT)


func _draw():
	if _trail_enabled:
		draw_circle(Vector2.ZERO, radius + 2, Color.red)
	draw_circle(Vector2.ZERO, radius, Color.white)


func _process(delta: float):
	if _spin:
		_velocity.y += _spin * delta * 3
		_spin -= _spin * delta * 3


func _physics_process(delta: float):
	var collision := move_and_collide(_velocity * _bonus_velocity * delta)
	if collision:
		var collider := collision.collider as Node
		if collider.is_in_group("paddles"):
			_collide_paddles(collision)
			_spawn_collision_sfx()
		elif collider.is_in_group("walls"):
			_collide_walls(collision)
			_spawn_collision_sfx()
			_audio_wall_bounce.play()
		elif collider.name == "LeftGoal":
			_collide_left_goal()
			_audio_goal.play()
		elif collider.name == "RightGoal":
			_collide_right_goal()
			_audio_goal.play()


func _collide_paddles(collision: KinematicCollision2D):
	var collider := collision.collider as Paddle
	match collider.paddleType:
		Globals.PaddleType.DIFFERENTIAL:
			_bonus_velocity = bonus_velocity_minimum + abs(collider.velocity.y) * 0.0015
			if collider.velocity.y:
				_spin = -collider.velocity.y * 3
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

	if _bonus_velocity > 1.0:
		_show_trail()
		_audio_power_hit.play()
	else:
		_hide_trail()
		_audio_hit.play()


func _collide_walls(collision: KinematicCollision2D):
	_velocity = _velocity.bounce(collision.normal)
	_spin = -_spin


func _collide_left_goal():
	_spawn_goal_sfx(Globals.Side.LEFT)
	_reset(Vector2.LEFT)
	emit_signal("right_scored")


func _collide_right_goal():
	_spawn_goal_sfx(Globals.Side.RIGHT)
	_reset(Vector2.RIGHT)
	emit_signal("left_scored")


func _reset(side: Vector2):
	position = _center;
	
	side.y = rand_range(-1.25, 1.25)
	_velocity = start_velocity * side.normalized()
	_bonus_velocity = 1.0
	_spin = 0.0

	_hide_trail()


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


func _spawn_goal_sfx(side : int):
	var sfx := GoalSfx.instance() as Node2D

	sfx.z_index = -1
	sfx.position = position
	match side:
		Globals.Side.LEFT:
			sfx.rotation = 0
		Globals.Side.RIGHT:
			sfx.rotation = PI

	get_parent().add_child(sfx)
