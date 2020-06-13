extends Node2D

export(Vector2) var endPoint
export(float) var dashStep

func _draw():
	var drawing = false
	var prevPoint = Vector2.ZERO
	
	var t = 0.0;
	while t <= 1.0:
		if drawing:
			draw_line(prevPoint, Vector2.ZERO.linear_interpolate(endPoint, t), Color(255, 255, 255), 10)
			drawing = false
		else:
			prevPoint = Vector2.ZERO.linear_interpolate(endPoint, t)
			drawing = true
		t += dashStep
