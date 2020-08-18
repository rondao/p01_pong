extends Node

const USER_PREFERENCES_FILE_NAME := "user://user_preferences.cfg"

var config: ConfigFile

const INPUT_SECTION := "input"

const PADDLE_TYPE_KEY := "paddle_type"
var paddle_type: int = Globals.PaddleType.NONE

const MOBILE_INPUT_KEY := "mobile_input"
var mobile_input: int = Globals.MobileInput.NONE


func _ready():
	config = ConfigFile.new()

	if config.load(USER_PREFERENCES_FILE_NAME) == OK:
		paddle_type = config.get_value(INPUT_SECTION, PADDLE_TYPE_KEY, Globals.PaddleType.NONE)
		mobile_input = config.get_value(INPUT_SECTION, MOBILE_INPUT_KEY, Globals.MobileInput.NONE)


func save_paddle_type(new_paddle_type: int):
	paddle_type = new_paddle_type

	config.set_value(INPUT_SECTION, PADDLE_TYPE_KEY, paddle_type)
	config.save(USER_PREFERENCES_FILE_NAME)


func save_mobile_input(new_mobile_input: int):
	mobile_input = new_mobile_input

	config.set_value(INPUT_SECTION, MOBILE_INPUT_KEY, mobile_input)
	config.save(USER_PREFERENCES_FILE_NAME)
