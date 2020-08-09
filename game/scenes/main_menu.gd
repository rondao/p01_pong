extends ColorRect


export(PackedScene) var PaddleSelection: PackedScene
export(PackedScene) var Game: PackedScene


func _on_PlayAgainstAI_pressed():
	pass # Replace with function body.


func _on_PlayRanked_pressed():
	if UserPreferences.paddle_type == Globals.PaddleType.NONE:
		var paddle_selection_popup := PaddleSelection.instance() as PopupPanel
		get_tree().get_root().add_child(paddle_selection_popup)

		paddle_selection_popup.popup()
# warning-ignore:return_value_discarded
		paddle_selection_popup.connect("popup_hide", self, "_play_game")
	else:
		_play_game()


func _on_Rankings_pressed():
	pass # Replace with function body.


func _play_game():
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(Game)
