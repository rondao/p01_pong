extends PopupPanel


func _mobile_input_selected(mobile_input: int):
	UserPreferences.save_mobile_input(mobile_input)
	hide()


func _on_OneHand_pressed():
	_mobile_input_selected(Globals.MobileInput.ONE_HAND)


func _on_TwoHands_pressed():
	_mobile_input_selected(Globals.MobileInput.TWO_HANDS)

