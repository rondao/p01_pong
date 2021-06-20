extends PaddleBounce
class_name AngularBounce

const BONUS_VELOCITY_MINIMUM := 0.65

const ANGULAR_Y_VELOCITY := 700
const ANGULAR_VELOCITY_RANGE := 0.8


static func create() -> Node:
	return (load("res://src/pong/bounce/angular_bounce.tscn") as PackedScene).instance()


func bounce(ball: Ball, collision: KinematicCollision2D) -> void:
	var paddle := collision.collider as Paddle

	var collision_relative_position := \
		collision.position.y - paddle.position.y
	var percent_distance_from_center := \
		collision_relative_position / ((collision.collider_shape as CollisionShape2D).shape as RectangleShape2D).extents.x

	ball.bonus_velocity = BONUS_VELOCITY_MINIMUM + ANGULAR_VELOCITY_RANGE * abs(percent_distance_from_center)

	ball.velocity.y = percent_distance_from_center * ANGULAR_Y_VELOCITY
	ball.velocity = ball.velocity.bounce(collision.normal)
	ball.spin = 0.0

	.bounce(ball, collision)
