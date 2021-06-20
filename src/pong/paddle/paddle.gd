extends KinematicBody2D
class_name Paddle

const SPEED := 600

const MAX_CHARGE := 0.5

var velocity: Vector2
var charge: float

var move_to: float


func _physics_process(delta: float):
	var collision := move_and_collide(velocity * delta * (1.0 - charge))
	if collision:
		var collider := collision.collider as Node
		if collider.is_in_group("ball"):
			collide_ball()
		elif collider.is_in_group("walls"):
			collide_walls()

	if move_to:
		velocity.y = SPEED * get_move_to_direction(move_to, SPEED * delta)



func get_move_to_direction(move_to_y: float, delta_speed: float) -> int:
	var relative_difference = move_to_y - position.y
	if abs(relative_difference) > delta_speed:
		return 1 if relative_difference > 0 else -1
	else:
		return 0


func handle_input(input: int, delta: float):
	if input & Globals.GameInput.UP:
		velocity.y = -SPEED
	elif input & Globals.GameInput.DOWN:
		velocity.y = SPEED
	else:
		velocity = Vector2.ZERO
		move_to = 0.0

	if input & Globals.GameInput.CHARGE:
		set_charge(min(charge + delta, MAX_CHARGE))
	else:
		set_charge(0.0)


func collide_ball():
	set_charge(0.0)


func collide_walls():
	velocity = Vector2.ZERO


func set_charge(charge_value: float):
	charge = charge_value
	modulate = Color(1.0, 1.0 - charge, 1.0 - charge)


func set_position(pos: Vector2):
	move_to = pos.y
