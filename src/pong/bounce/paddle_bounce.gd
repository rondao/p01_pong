extends Bounce
class_name PaddleBounce

signal normally_hitted()
signal powered_hitted()

const BOUNCE_ACCEL := 1.2
const MAXIMUM_X_VELOCITY := 1600

func bounce(ball: Ball, collision: KinematicCollision2D) -> void:
	.bounce(ball, collision)
	var paddle := collision.collider as Paddle

	ball.velocity *= BOUNCE_ACCEL
	ball.velocity.x = sign(ball.velocity.x) * min(abs(ball.velocity.x), MAXIMUM_X_VELOCITY)

	ball.bonus_velocity += paddle.charge
	ball.spin *= 1.0 + paddle.charge

	emit_signal("powered_hitted") if ball.bonus_velocity > 1.0 else emit_signal("normally_hitted")
