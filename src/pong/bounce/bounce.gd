extends Node2D
class_name Bounce


func bounce(ball, _collision: KinematicCollision2D) -> void:
	spawn_collision_sfx(ball.position)


func spawn_collision_sfx(pos: Vector2):
	var sfx := CollisionSfx.create()
	sfx.position = pos
	get_tree().get_root().add_child(sfx)
