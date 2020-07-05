extends Node2D

onready var _particles := $Particles2D as Particles2D

# warning-ignore:unused_argument
func _process(delta):
	if not _particles.emitting:
		queue_free()

func _ready():
	_particles.emitting = true

