extends Node2D
class_name CollisionSfx

const RADIUS := 50


static func create() -> CollisionSfx:
	return (load("res://src/pong/sfx/collision_sfx.tscn") as PackedScene).instance() as CollisionSfx


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color.white)


func _on_Animation_animation_finished(_anim_name: String) -> void:
	queue_free()
