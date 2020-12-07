extends Control

var _ball_scene := load("res://game/scenes/ball.tscn") as PackedScene


func _ready():
	pass


func _on_Timer_timeout():
	var ball := _ball_scene.instance() as Ball
	add_child(ball)

	ball.restart(rect_size / 2, Vector2.LEFT if randf() < 0.5 else Vector2.RIGHT)
	ball.connect("collided_goal", ball, "free_on_collision")
