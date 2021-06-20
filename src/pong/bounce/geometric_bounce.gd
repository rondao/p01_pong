extends PaddleBounce
class_name GeometricBounce


static func create() -> Node:
	return (load("res://src/pong/bounce/geometric_bounce.tscn") as PackedScene).instance()


func bounce(ball: Ball, collision: KinematicCollision2D) -> void:
	ball.velocity = ball.velocity.bounce(collision.normal)
	ball.bonus_velocity = 1.0
	ball.spin = 0.0

	.bounce(ball, collision)
