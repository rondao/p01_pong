extends KinematicBody2D
class_name Paddle

enum PlayerType {NONE, AI_01, AI_02, HUMAN_01, HUMAN_02, NETWORK}
export(PlayerType) var player_type: int = PlayerType.NONE

var paddle_type: int

export(int) var speed: int
var velocity := Vector2()

var charge := 0.0
var _max_charge := 0.5

var _move_to: float


func _ready():
	paddle_type = UserPreferences.paddle_type


func _process(delta: float):
	if player_type == PlayerType.AI_01 or player_type == PlayerType.HUMAN_01:
			_handle_input("player_01", delta)
	elif player_type == PlayerType.AI_02 or player_type == PlayerType.HUMAN_02:
			_handle_input("player_02", delta)

	if _move_to:
		velocity.y = speed * _get_move_to_direction(_move_to, speed * delta)


func _physics_process(delta: float):
	if not player_type == PlayerType.NETWORK:
		var collision := move_and_collide(velocity * delta * (1.0 - charge))
		if collision:
			var collider := collision.collider as Node
			if collider.is_in_group("ball"):
				_collide_ball()
			elif collider.is_in_group("walls"):
				_collide_walls()
	else:
		position += velocity * delta * (1.0 - charge)


func _handle_input(player_number: String, delta: float):
	if Input.is_action_pressed(player_number + "_up"):
		velocity.y = -speed
	elif Input.is_action_pressed(player_number + "_down"):
		velocity.y = speed
	elif Input.is_action_pressed(player_number + "_move_to"):
		_move_to = Input.get_action_strength(player_number + "_move_to")
	else:
		velocity = Vector2.ZERO
		_move_to = 0.0

	if Input.is_action_pressed(player_number + "_charge"):
		set_charge(min(charge + delta, _max_charge))
	else:
		set_charge(0.0)


func _get_move_to_direction(move_to_y: float, delta_speed: float) -> int:
	var relative_difference = move_to_y - position.y
	if abs(relative_difference) > delta_speed:
		return 1 if relative_difference > 0 else -1
	else:
		return 0


func _collide_ball():
	set_charge(0.0)


func _collide_walls():
	velocity = Vector2.ZERO


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
	_move_to = pos.y
