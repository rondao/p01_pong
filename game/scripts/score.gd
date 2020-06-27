extends Label


func _increase_score():
	text = str(int(text) + 1)


func _on_Ball_left_scored():
	_increase_score()


func _on_Ball_right_scored():
	_increase_score()
