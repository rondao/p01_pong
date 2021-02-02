extends PopupPanel


func _paddle_selected(paddle_type: int):
	UserPreferences.save_paddle_type(paddle_type)
	queue_free()


func _on_Geometric_pressed():
	_paddle_selected(Globals.PaddleType.GEOMETRIC)


func _on_Angular_pressed():
	_paddle_selected(Globals.PaddleType.ANGULAR)


func _on_Differential_pressed():
	_paddle_selected(Globals.PaddleType.DIFFERENTIAL)
