extends PopupPanel
class_name EndGamePopup

onready var _label := $Margin/HBox/WonOrLost as Label

var _label_text := "WON_OR_LOST"
const _won_text := "Won"
const _lost_text := "Lost"


static func create_popup(won: bool) -> PopupPanel:
	var end_game_popup := (load("res://game/scenes/end_game_popup.tscn") as PackedScene).instance() as EndGamePopup
	end_game_popup._label_text = _won_text if won else _lost_text

	return end_game_popup


static func create_popup_with_side_victory(side: int) -> PopupPanel:
	var end_game_popup := (load("res://game/scenes/end_game_popup.tscn") as PackedScene).instance() as EndGamePopup

	match side:
		Globals.Side.LEFT:
			end_game_popup._label_text = "Left " + _won_text
		Globals.Side.RIGHT:
			end_game_popup._label_text = "Right " + _won_text

	return end_game_popup


func _ready():
	_label.text = _label_text


func _on_Quit_pressed():
	hide()
