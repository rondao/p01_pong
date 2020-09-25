extends KinematicBody2D
class_name Paddle

enum PlayerType {NONE, AI, HUMAN_01, HUMAN_02, NETWORK}
var player_type: int = PlayerType.NONE

var paddle_type: int

export(int) var speed: int
var velocity := Vector2()

var charge := 0.0
var _max_charge := 0.5


func _ready():
	paddle_type = UserPreferences.paddle_type


func _process(delta: float):
	match player_type:
		PlayerType.HUMAN_01:
			_handle_input("player_01", delta)
		PlayerType.HUMAN_02:
			_handle_input("player_02", delta)


func _physics_process(delta: float):
	if player_type == PlayerType.HUMAN_01 or player_type == PlayerType.HUMAN_02:
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
		var relative_difference = move_to - (position.y / get_viewport().size.y)

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
		_update_charge(min(charge + delta, _max_charge))
		velocity.y *= 1.0 - charge
	else:
		_update_charge(0.0)


func _collide_ball():
	_update_charge(0.0)


func _collide_walls():
	velocity = Vector2.ZERO


func _update_charge(charge_value: float):
	GameServer.send_paddle_charge(charge_value)
	set_charge(charge_value)


func set_player_type(new_player_type: int):
	player_type = new_player_type

	# Network players will handle their collisions and send to us.
	if player_type == PlayerType.NETWORK:
		set_collision_layer(0)
		set_collision_mask(0)


func set_charge(charge_value: float):
	charge = charge_value
	modulate = Color(1.0, 1.0 - charge, 1.0 - charge)


func set_position(pos: Vector2):
	position = pos
