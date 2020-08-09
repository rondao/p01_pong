extends ColorRect


export(PackedScene) var PaddleTypeSelection: PackedScene
export(PackedScene) var MobileInputSelection: PackedScene

export(PackedScene) var Game: PackedScene


func _on_PlayAgainstAI_pressed():
	pass # Replace with function body.


func _on_PlayRanked_pressed():
	if OS.has_touchscreen_ui_hint():
		if UserPreferences.mobile_input == Globals.MobileInput.NONE:
			yield(_popup_mobile_input_selection(), "popup_hide")

	if UserPreferences.paddle_type == Globals.PaddleType.NONE:
		yield(_popup_paddle_type_selection(), "popup_hide")

	_play_game()


func _on_Rankings_pressed():
	pass # Replace with function body.


func _popup_paddle_type_selection() -> PopupPanel:
	var paddle_selection_popup := PaddleTypeSelection.instance() as PopupPanel
	get_tree().get_root().add_child(paddle_selection_popup)

	paddle_selection_popup.popup()
	return paddle_selection_popup


func _popup_mobile_input_selection() -> PopupPanel:
	var mobile_input_selection_popup := MobileInputSelection.instance() as PopupPanel
	get_tree().get_root().add_child(mobile_input_selection_popup)

	mobile_input_selection_popup.popup()
	return mobile_input_selection_popup


func _play_game():
# warning-ignore:return_value_discarded
	get_tree().change_scene_to(Game)
