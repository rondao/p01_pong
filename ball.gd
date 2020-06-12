extends KinematicBody2D

export(float) var radius

export(Vector2) var startVelocity
var velocity = Vector2()

func _ready():
	velocity = startVelocity

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.white)

# warning-ignore:unused_argument
func _physics_process(delta):
# warning-ignore:return_value_discarded
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.normal)
