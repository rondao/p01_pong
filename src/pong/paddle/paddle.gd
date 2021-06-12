extends KinematicBody2D
class_name Paddle

const SPEED := 600

const MAX_CHARGE := 0.5

var paddle_type: int = UserPreferences.PaddleType.NONE

var player_input: String
onready var netplayer: Netcode.LocalPlayer = Netcode.LocalPlayer.create()

var velocity: Vector2
var charge: float

var move_to: float


func _ready():
	paddle_type = UserPreferences.paddle_type


func _physics_process(delta: float):
	var current_frame := get_tree().get_frame()
	netplayer.set_input(current_frame, get_local_input(player_input))
	handle_input(netplayer.get_input(current_frame), delta)

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
	if input & INPUT_UP:
		velocity.y = -SPEED
	elif input & INPUT_DOWN:
		velocity.y = SPEED
	else:
		velocity = Vector2.ZERO
		move_to = 0.0

	if input & INPUT_CHARGE:
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


const INPUT_NONE   := 0
const INPUT_UP     := 1
const INPUT_DOWN   := 2
const INPUT_CHARGE := 4


func get_local_input(player_number: String) -> int:
	var input := INPUT_NONE

	if Input.is_action_pressed(player_number + "_up"):
		input |= INPUT_UP
	elif Input.is_action_pressed(player_number + "_down"):
		input |= INPUT_DOWN
	else:
		input = INPUT_NONE

	if Input.is_action_pressed(player_number + "_charge"):
		input |= INPUT_CHARGE

	return input
