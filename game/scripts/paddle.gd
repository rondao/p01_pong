extends KinematicBody2D
class_name Paddle

enum Player {HUMAN_01, HUMAN_02, NONE}
export(Player) var player: int

export(Globals.PaddleType) var paddleType: int

export(int) var speed: int
var velocity := Vector2()

var charge := 0.0
var _max_charge := 0.5


func _physics_process(delta: float):
	match player:
		Player.HUMAN_01:
			_handle_input("player_01", delta)
		Player.HUMAN_02:
			_handle_input("player_02", delta)

	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.collider as Node
		if collider.is_in_group("ball"):
			_collide_ball()
		elif collider.is_in_group("walls"):
			_collide_walls()


func _handle_input(player_number: String, delta: float):
	if Input.is_action_pressed(player_number + "_up"):
		velocity.y = -speed
	elif Input.is_action_pressed(player_number + "_down"):
		velocity.y = speed
	elif Input.is_action_pressed(player_number + "_move_to"):
		var move_to := Input.get_action_strength(player_number + "_move_to")
		var relative_difference = move_to - (position.y / 1080)

		if abs(relative_difference) > 0.01:
			if relative_difference < 0:
				velocity.y = -speed
			else:
				velocity.y = speed
		else:
			velocity = Vector2.ZERO
	else:
		velocity = Vector2.ZERO

	if Input.is_action_pressed(player_number + "_charge"):
		_set_charge(min(charge + delta, _max_charge))
		velocity.y *= 1.0 - charge
	else:
		_set_charge(0.0)


func _collide_ball():
	_set_charge(0.0)


func _collide_walls():
	velocity = Vector2.ZERO


func _set_charge(charge_value: float):
	charge = charge_value
	modulate = Color(1.0, 1.0 - charge, 1.0 - charge)
