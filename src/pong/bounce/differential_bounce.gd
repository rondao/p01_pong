extends PaddleBounce
class_name DifferentialBounce

const BONUS_VELOCITY_MINIMUM := 0.65


static func create() -> Node:
	return (load("res://src/pong/bounce/differential_bounce.tscn") as PackedScene).instance()


func bounce(ball: Ball, collision: KinematicCollision2D) -> void:
	var paddle := collision.collider as Paddle

	ball.bonus_velocity = BONUS_VELOCITY_MINIMUM + abs(paddle.velocity.y) * 0.001
	if paddle.velocity.y:
		ball.spin = -paddle.velocity.y * 1.75
		ball.velocity.y = paddle.velocity.y * 1.5
	else:
		ball.spin = -ball.velocity.y * 1.5
	ball.velocity = ball.velocity.bounce(collision.normal)

	.bounce(ball, collision)
