extends Node2D

export(float) var radius

func _draw():
	draw_circle(Vector2.ZERO, radius, Color.white)

# warning-ignore:unused_argument
func _on_Animation_animation_finished(anim_name):
	queue_free()
