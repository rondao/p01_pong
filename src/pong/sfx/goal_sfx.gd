extends Node2D
class_name GoalSfx

onready var particles := $Particles2D as Particles2D


static func create() -> GoalSfx:
	return (load("res://src/pong/sfx/goal_sfx.tscn") as PackedScene).instance() as GoalSfx


func _process(_delta: float) -> void:
	if not particles.emitting:
		queue_free()


func _ready() -> void:
	particles.emitting = true

