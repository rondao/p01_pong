extends Popup


export(PackedScene) var PaddleSelection: PackedScene


# warning-ignore:unused_argument
func _paddle_selected(paddle_type: int):
	pass


func _on_Geometric_pressed():
	_paddle_selected(Globals.PaddleType.GEOMETRIC)


func _on_Angular_pressed():
	_paddle_selected(Globals.PaddleType.ANGULAR)


func _on_Differential_pressed():
	_paddle_selected(Globals.PaddleType.DIFFERENTIAL)
