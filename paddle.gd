extends KinematicBody2D

enum Player {HUMAN_01, HUMAN_02, NONE}
export(Player) var player

export(Globals.PaddleType) var paddleType

export(int) var speed
var velocity = Vector2()

var charge = 0.0
var _max_charge = 0.5

func _physics_process(delta):
	match player:
		Player.HUMAN_01:
			_handle_input("player_01", delta)
		Player.HUMAN_02:
			_handle_input("player_02", delta)

	var collision = move_and_collide(velocity * delta)
	if collision:
		if collision.collider.is_in_group("ball"):
			_collide_ball()
		elif collision.collider.is_in_group("walls"):
			_collide_walls()

func _handle_input(player_number, delta):
	if Input.is_action_pressed(player_number + "_up"):
		velocity.y = -speed
	elif Input.is_action_pressed(player_number + "_down"):
		velocity.y = speed
	else:
		velocity = Vector2.ZERO

	if Input.is_action_pressed(player_number + "_charge"):
		charge = min(charge + delta, _max_charge)
		velocity.y *= 1.0 - charge
	else:
		charge = 0.0

func _collide_ball():
	charge = 0.0

func _collide_walls():
	velocity = Vector2.ZERO
