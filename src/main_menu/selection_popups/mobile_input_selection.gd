extends PopupPanel
class_name MobileInputSelection


static func create() -> MobileInputSelection:
	return (load("res://src/main_menu/selection_popups/mobile_input_selection.tscn") as PackedScene).instance() as MobileInputSelection


func _mobile_input_selected(mobile_input: int):
	UserPreferences.save_mobile_input(mobile_input)
	queue_free()


func _on_OneHand_pressed():
	_mobile_input_selected(UserPreferences.MobileInput.ONE_HAND)


func _on_TwoHands_pressed():
	_mobile_input_selected(UserPreferences.MobileInput.TWO_HANDS)

