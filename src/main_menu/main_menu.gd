extends ColorRect

signal game_started()


static func create() -> Node:
	return (load("res://src/main_menu/main_menu.tscn") as PackedScene).instance()


func _ready():
	if GameServer.is_connected_to_server():
		_enable_ranked_game()
	else:
		GameServer.connect("server_connected", self, "_enable_ranked_game")


func _enable_ranked_game():
	($MenuLayer/Margin/HBox/MainButtons/PlayRanked as Button).disabled = false


func _on_PlayAgainstAI_pressed():
	yield(_check_user_options_set(), "completed")
	_start_game(PongGame.create(PongGame.GameType.LOCAL_AI))


func _on_PlayRanked_pressed():
	yield(_check_user_options_set(), "completed")

	var searching_popup := _popup_searching_game()
	connect("game_started", searching_popup, "queue_free")

	GameServer.connect("game_found", self, "_on_Network_game_found")
	GameServer.request_matchmaking()


func _on_Rankings_pressed():
	yield(_check_user_options_set(), "completed")
	_start_game(PongGame.create(PongGame.GameType.LOCAL_MULTIPLAYER))


func _on_Settings_pressed():
	yield(_popup_paddle_type_selection(), "popup_hide")
	if OS.has_touchscreen_ui_hint():
		yield(_popup_mobile_input_selection(), "popup_hide")


func _on_Network_game_found(side: int, rng_seed: int):
	seed(rng_seed)
	_start_game(PongGame.create(PongGame.GameType.NETWORK_MULTIPLAYER, side))


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
	var paddle_selection_popup := PaddleSelection.create()
	$PopupLayer.add_child(paddle_selection_popup)

	paddle_selection_popup.popup()
	return paddle_selection_popup


func _popup_mobile_input_selection() -> PopupPanel:
	var mobile_input_selection_popup := MobileInputSelection.create()
	$PopupLayer.add_child(mobile_input_selection_popup)

	mobile_input_selection_popup.popup()
	return mobile_input_selection_popup


func _popup_searching_game() -> PopupPanel:
	var loading_popup := (load("res://src/main_menu/searching_game.tscn") as PackedScene).instance() as PopupPanel
	$PopupLayer.add_child(loading_popup)

	loading_popup.popup()
	return loading_popup


func _start_game(game: PongGame):
	emit_signal("game_started")

	get_tree().get_root().add_child(game)
	get_tree().get_root().remove_child(self)

	self.queue_free()
