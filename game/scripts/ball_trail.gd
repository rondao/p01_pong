extends Line2D
class_name BallTrail

export(int) var length: int
export(float) var timer: float

var _elapsed_time := 0.0
var _active := false


func _process(delta: float):
	# Freeze trail position so it is not transformed with parent.
	global_transform = Transform2D.IDENTITY

	if _active:
		_elapsed_time += delta

		if _elapsed_time > timer:
			add_point((get_parent() as Node2D).position)
			if get_point_count() >= length:
				remove_point(0)
			_elapsed_time -= timer
	else:
		if get_point_count() > 0:
			remove_point(0)


func enable():
	_active = true
	_elapsed_time = 0


func disable():
	_active = false
