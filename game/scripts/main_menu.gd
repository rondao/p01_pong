extends ColorRect


export(PackedScene) var PaddleTypeSelection: PackedScene
export(PackedScene) var MobileInputSelection: PackedScene


func _ready():
	for argument in OS.get_cmdline_args():
		if argument == "--server":
			$Margin.queue_free()
			Network.connect("game_found", self, "_game_found")
			Network.start_server()


func _on_PlayAgainstAI_pressed():
	yield(_check_user_options_set(), "completed")
	_start_game(PongGame.create_game(PongGame.GameType.LOCAL_AI))


func _on_PlayRanked_pressed():
	yield(_check_user_options_set(), "completed")
	Network.connect("game_found", self, "_game_found")
	Network.request_ranked_game()


func _on_Rankings_pressed():
	yield(_check_user_options_set(), "completed")
	_start_game(PongGame.create_game(PongGame.GameType.LOCAL_MULTIPLAYER))


func _check_user_options_set():
	if OS.has_touchscreen_ui_hint():
		if UserPreferences.mobile_input == Globals.MobileInput.NONE:
			yield(_popup_mobile_input_selection(), "popup_hide")

	if UserPreferences.paddle_type == Globals.PaddleType.NONE:
		yield(_popup_paddle_type_selection(), "popup_hide")

	# Below yield is needed to guarantee this function returns a GDFunctionstate
	#  which completes, otherwise it will crash when yielding to it.
	yield(get_tree(), "idle_frame")

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
	if get_tree().is_network_server():
		var game := PongGame.create_game(PongGame.GameType.SERVER, side)
		_start_game(game)
	else:
		var game := PongGame.create_game(PongGame.GameType.NETWORK_MULTIPLAYER, side)
		_start_game(game)


func _start_game(game: PongGame):
	get_tree().get_root().add_child(game)
	get_tree().get_root().remove_child(self)

	self.queue_free()
