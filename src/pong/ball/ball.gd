extends KinematicBody2D
class_name Ball

signal normally_hitted()
signal powered_hitted()

signal collided_left_goal()
signal collided_right_goal()

const RADIUS := 15
const START_VELOCITY := Vector2(500, 300)
const BALL_SPAWNING_ANIMATION := "ball_spawn"

var velocity := Vector2()
var bonus_velocity := 1.0

var spin := 0.0

onready var trail := $Trail as BallTrail

onready var animation := $Animation as AnimationPlayer


static func create() -> Ball:
	return (load("res://src/pong/ball/ball.tscn") as PackedScene).instance() as Ball


func _draw():
	if trail.active:
		draw_circle(Vector2.ZERO, RADIUS + 2, Color.red)
	draw_circle(Vector2.ZERO, RADIUS, Color.white)


func physics_process(delta: float):
	if spin:
		velocity.y += spin * delta * 3
		spin -= spin * delta * 3

	var collision := move_and_collide(velocity * bonus_velocity * delta)
	if collision:
		var collider := collision.collider as Node2D
		if collider.has_node("Bounce"):
			(collider.get_node("Bounce") as Bounce).bounce(self, collision)
			emit_signal("powered_hitted") if bonus_velocity > 1.0 else emit_signal("normally_hitted")
		elif collider.name == "LeftGoal":
			emit_signal("collided_left_goal")
		elif collider.name == "RightGoal":
			emit_signal("collided_right_goal")


func restart_left(new_position: Vector2) -> void:
	restart(Vector2.LEFT, new_position)


func restart_right(new_position: Vector2) -> void:
	restart(Vector2.RIGHT, new_position)


func restart(side: Vector2, new_position: Vector2) -> void:
	position = new_position;

	side.y = velocity.normalized().y
	velocity = START_VELOCITY * side.normalized()
	bonus_velocity = 1.0
	spin = 0.0

	trail.disable()
	update()

	animation.play(BALL_SPAWNING_ANIMATION)
