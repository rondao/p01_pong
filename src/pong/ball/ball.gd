extends KinematicBody2D
class_name Ball

signal collided_goal()
signal collided_paddle()

const RADIUS := 15

const BOUNCE_ACCEL := 1.2
const START_VELOCITY := Vector2(500, 300)

const BONUS_VELOCITY_MINIMUM := 0.65
const BONUS_VELOCITY_RANGE := 0.8

const ANGULAR_Y_VELOCITY := 700
const MAXIMUM_X_VELOCITY := 1600

const BALL_SPAWNING_ANIMATION := "ball_spawn"

var velocity := Vector2()
var bonus_velocity := 1.0
var latency_speed_adjustment := 1.0

var spin := 0.0

var trail_enabled := false
onready var trail := $Trail as BallTrail

onready var audio_hit := $AudioHit as AudioStreamPlayer2D
onready var audio_power_hit := $AudioPowerHit as AudioStreamPlayer2D
onready var audio_wall_bounce := $AudioWallBounce as AudioStreamPlayer2D

onready var animation := $Animation as AnimationPlayer


static func create() -> Ball:
	return (load("res://src/pong/ball/ball.tscn") as PackedScene).instance() as Ball


func _draw():
	if trail_enabled:
		draw_circle(Vector2.ZERO, RADIUS + 2, Color.red)
	draw_circle(Vector2.ZERO, RADIUS, Color.white)


func _process(delta: float):
	if spin:
		velocity.y += spin * latency_speed_adjustment * delta * 3
		spin -= spin * latency_speed_adjustment * delta * 3


func _physics_process(delta: float):
	var collision := move_and_collide(velocity * bonus_velocity * latency_speed_adjustment * delta)
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
			audio_wall_bounce.play()
		elif collider.name == "LeftGoal":
			_collided_goal(Globals.Side.LEFT)
		elif collider.name == "RightGoal":
			_collided_goal(Globals.Side.RIGHT)


func restart(new_position: Vector2, side: Vector2):
	position = new_position;
	
	side.y = rand_range(-1.25, 1.25)
	velocity = START_VELOCITY * side.normalized()
	bonus_velocity = 1.0
	spin = 0.0

	_hide_trail()
	animation.play(BALL_SPAWNING_ANIMATION)


func _collided_goal(side: int):
	GameServer.send_collided_goal(side)
	emit_signal("collided_goal", side)


func apply_collision(_new_position: Vector2, _new_velocity: Vector2, _newbonus_velocity: float, _new_spin: float):
	position = _new_position
	velocity = _new_velocity
	bonus_velocity = _newbonus_velocity
	spin = _new_spin
	latency_speed_adjustment = 1

	_after_paddle_collision()


func _collide_paddles(collision: KinematicCollision2D):
	var collider := collision.collider as Paddle
	match collider.paddle_type:
		Globals.PaddleType.DIFFERENTIAL:
			bonus_velocity = BONUS_VELOCITY_MINIMUM + abs(collider.velocity.y) * 0.001
			if collider.velocity.y:
				spin = -collider.velocity.y * 1.75
				velocity.y = collider.velocity.y * 1.5
			else:
				spin = -velocity.y * 1.5
			velocity = velocity.bounce(collision.normal)
		Globals.PaddleType.ANGULAR:
			var collision_relative_position := \
				collision.position.y - collider.position.y
			var percent_distance_from_center := \
				collision_relative_position / ((collision.collider_shape as CollisionShape2D).shape as RectangleShape2D).extents.x

			bonus_velocity = BONUS_VELOCITY_MINIMUM + BONUS_VELOCITY_RANGE * abs(percent_distance_from_center)

			velocity.y = percent_distance_from_center * ANGULAR_Y_VELOCITY
			velocity = velocity.bounce(collision.normal)
			spin = 0.0
		Globals.PaddleType.GEOMETRIC:
			velocity = velocity.bounce(collision.normal)
			bonus_velocity = 1.0
			spin = 0.0

	velocity *= BOUNCE_ACCEL
	velocity.x = sign(velocity.x) * min(abs(velocity.x), MAXIMUM_X_VELOCITY)

	bonus_velocity += collider.charge
	spin *= 1.0 + collider.charge

	GameServer.send_ball_collided(position, velocity, bonus_velocity, spin)
	_after_paddle_collision()


func _after_paddle_collision():
	if bonus_velocity > 1.0:
		_show_trail()
		audio_power_hit.play()
	else:
		_hide_trail()
		audio_hit.play()
	_spawn_collision_sfx()


func _collide_walls(collision: KinematicCollision2D):
	velocity = velocity.bounce(collision.normal)
	spin = -spin


func _show_trail():
	trail_enabled = true
	trail.enable()
	update()


func _hide_trail():
	trail_enabled = false
	trail.disable()
	update()


func _spawn_collision_sfx():
	var sfx := CollisionSfx.create()
	sfx.position = position
	get_parent().add_child(sfx)


func free_on_collision(_side: int):
	queue_free()
