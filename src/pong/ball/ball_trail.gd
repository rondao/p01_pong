extends Line2D
class_name BallTrail

const LENGTH := 15
const TIMER := 0.01

var elapsed_time := 0.0
var active := false


func _process(delta: float):
	# Freeze trail position so it is not transformed with parent.
	global_transform = Transform2D.IDENTITY

	if active:
		elapsed_time += delta

		if elapsed_time > TIMER:
			add_point((get_parent() as Node2D).position)
			if get_point_count() >= LENGTH:
				remove_point(0)
			elapsed_time -= TIMER
	else:
		if get_point_count() > 0:
			remove_point(0)


func enable():
	active = true
	elapsed_time = 0


func disable():
	active = false
