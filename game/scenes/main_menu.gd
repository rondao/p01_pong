extends MarginContainer


export(PackedScene) var PaddleSelection: PackedScene


func _on_PlayAgainstAI_pressed():
	pass # Replace with function body.


func _on_PlayRanked_pressed():
	var paddle_selection_popup := PaddleSelection.instance() as PopupDialog
	get_tree().get_root().add_child(paddle_selection_popup)
	paddle_selection_popup.popup()


func _on_Rankings_pressed():
	pass # Replace with function body.
