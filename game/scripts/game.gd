extends Node2D


export(PackedScene) var MobileInputOneHand: PackedScene
export(PackedScene) var MobileInputTwoHands: PackedScene


func _ready():
	if OS.has_touchscreen_ui_hint():
		match UserPreferences.mobile_input:
			Globals.MobileInput.ONE_HAND:
				add_child(MobileInputOneHand.instance())
			Globals.MobileInput.TWO_HANDS:
				add_child(MobileInputTwoHands.instance())
