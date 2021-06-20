extends Bounce

onready var audio_wall_bounce := $AudioWallBounce as AudioStreamPlayer2D


func bounce(ball: Ball, collision: KinematicCollision2D) -> void:
	.bounce(ball, collision)
	ball.velocity = ball.velocity.bounce(collision.normal)
	ball.spin *= -1

	audio_wall_bounce.play()
