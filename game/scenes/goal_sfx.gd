extends Node2D

onready var _particles := $Particles2D as Particles2D

func _ready():
	_particles.emitting = true

