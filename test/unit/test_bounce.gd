extends "res://addons/gut/test.gd"


func test_bounce_spawn_sfx() -> void:
	ignore_method_when_doubling(Ball, "create")
	var ball = double(Ball).new()
	var bounce := Bounce.new()

	add_child_autoqfree(bounce)

	bounce.bounce(ball, null)
	assert_not_null(get_parent().get_parent().get_parent().get_node_or_null("CollisionSFX"))


func test_paddle_bounce_normally_hitted() -> void:
	ignore_method_when_doubling(Ball, "create")
	ignore_method_when_doubling(Paddle, "create")

	var ball = double(Ball).new()
	var paddle = double(Paddle).new()
	var bounce := PaddleBounce.new()
	var collision = double(KinematicCollision2D).new()

	add_child_autoqfree(bounce)
	watch_signals(bounce)

	stub(collision, "get_collider").to_return(paddle)
	
	ball.bonus_velocity = 1.0
	ball.spin = 0.0
	paddle.charge = 0.0

	ball.velocity = Vector2(-PaddleBounce.MAXIMUM_X_VELOCITY - 200, 900)

	bounce.bounce(ball, collision)
	assert_between(ball.velocity.x, -PaddleBounce.MAXIMUM_X_VELOCITY, PaddleBounce.MAXIMUM_X_VELOCITY)
	assert_eq(ball.bonus_velocity, 1.0)
	assert_eq(ball.spin, 0.0)
	assert_signal_emit_count(bounce, "powered_hitted", 0)
	assert_signal_emit_count(bounce, "normally_hitted", 1)


func test_paddle_bounce_powered_hitted() -> void:
	ignore_method_when_doubling(Ball, "create")
	ignore_method_when_doubling(Paddle, "create")

	var ball = double(Ball).new()
	var paddle = double(Paddle).new()
	var bounce := PaddleBounce.new()
	var collision = double(KinematicCollision2D).new()

	add_child_autoqfree(bounce)
	watch_signals(bounce)

	stub(collision, "get_collider").to_return(paddle)
	
	ball.bonus_velocity = 1.0
	ball.spin = 0.0
	paddle.charge = 0.4

	ball.velocity = Vector2(PaddleBounce.MAXIMUM_X_VELOCITY + 200, -400)

	bounce.bounce(ball, collision)
	assert_between(ball.velocity.x, -PaddleBounce.MAXIMUM_X_VELOCITY, PaddleBounce.MAXIMUM_X_VELOCITY)
	assert_eq(ball.bonus_velocity, 1.4)
	assert_eq(ball.spin, 0.0)
	assert_signal_emit_count(bounce, "powered_hitted", 1)
	assert_signal_emit_count(bounce, "normally_hitted", 0)

func test_geometric_bounce() -> void:
	ignore_method_when_doubling(Ball, "create")
	ignore_method_when_doubling(Paddle, "create")

	var ball = double(Ball).new()
	var paddle = double(Paddle).new()
	var bounce := GeometricBounce.new()
	var collision = double(KinematicCollision2D).new()

	add_child_autoqfree(bounce)

	stub(collision, "get_normal").to_return(Vector2.LEFT)
	stub(collision, "get_collider").to_return(paddle)
	
	ball.bonus_velocity = 1.0
	ball.spin = 0.0
	paddle.charge = 0.0

	ball.velocity = Vector2(500, 300)
	var expected_velocity: Vector2 = ball.velocity.bounce(collision.get_normal())

	bounce.bounce(ball, collision)
	assert_eq(ball.velocity.normalized().snapped(Vector2(0.1, 0.1)), expected_velocity.normalized().snapped(Vector2(0.1, 0.1)))
	assert_eq(ball.bonus_velocity, 1.0)
	assert_eq(ball.spin, 0.0)
