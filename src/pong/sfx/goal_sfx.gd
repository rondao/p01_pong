extends Node2D

onready var _particles := $Particles2D as Particles2D


func _process(_delta: float):
	if not _particles.emitting:
		queue_free()


func _ready():
	_particles.emitting = true

