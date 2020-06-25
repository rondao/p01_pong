extends Line2D

export(int) var length

func _ready():
	for i in length:
		add_point((get_parent() as Node2D).position)

# warning-ignore:unused_argument
func _process(delta):
	# Freeze trail position so it is not transformed with parent.
	global_transform = Transform2D.IDENTITY

	add_point((get_parent() as Node2D).position)
	remove_point(0)
