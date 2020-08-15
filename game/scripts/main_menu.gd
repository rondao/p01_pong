extends ColorRect


export(PackedScene) var PaddleTypeSelection: PackedScene
export(PackedScene) var MobileInputSelection: PackedScene

export(PackedScene) var Game: PackedScene


func _on_PlayAgainstAI_pressed():
	_check_user_options_set()
	_play_game(PongGame.GameType.LOCAL_AI)


func _on_PlayRanked_pressed():
	_check_user_options_set()
	Network.connect("game_found", self, "_game_found")
	Network.request_ranked_game()


func _on_Rankings_pressed():
	_check_user_options_set()
	_play_game(PongGame.GameType.LOCAL_MULTIPLAYER)


func _check_user_options_set():
	if OS.has_touchscreen_ui_hint():
		if UserPreferences.mobile_input == Globals.MobileInput.NONE:
			yield(_popup_mobile_input_selection(), "popup_hide")

	if UserPreferences.paddle_type == Globals.PaddleType.NONE:
		yield(_popup_paddle_type_selection(), "popup_hide")


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


func _game_found(side: int, rng_seed: int):
	seed(rng_seed)
	_play_game(PongGame.GameType.NETWORK_MULTIPLAYER, side)


func _play_game(game_type: int, network_side: int = Globals.Side.NONE):
	var game := Game.instance() as PongGame
	game.game_type = game_type
	game.network_side = network_side

	get_tree().get_root().add_child(game)
	get_tree().get_root().remove_child(self)

	self.queue_free()
