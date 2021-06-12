extends Node

enum PaddleType {NONE, GEOMETRIC, ANGULAR, DIFFERENTIAL}
enum MobileInput {NONE, ONE_HAND, TWO_HANDS}

const USER_PREFERENCES_FILE_NAME := "user://user_preferences.cfg"
var config: ConfigFile

const INPUT_SECTION := "input"

const PADDLE_TYPE_KEY := "paddle_type"
var paddle_type: int = PaddleType.NONE

const MOBILE_INPUT_KEY := "mobile_input"
var mobile_input: int = MobileInput.NONE


func _ready():
	config = ConfigFile.new()

	if config.load(USER_PREFERENCES_FILE_NAME) == OK:
		paddle_type = config.get_value(INPUT_SECTION, PADDLE_TYPE_KEY, PaddleType.NONE)
		mobile_input = config.get_value(INPUT_SECTION, MOBILE_INPUT_KEY, MobileInput.NONE)


func save_paddle_type(new_paddle_type: int):
	paddle_type = new_paddle_type

	config.set_value(INPUT_SECTION, PADDLE_TYPE_KEY, paddle_type)
	config.save(USER_PREFERENCES_FILE_NAME)


func save_mobile_input(new_mobile_input: int):
	mobile_input = new_mobile_input

	config.set_value(INPUT_SECTION, MOBILE_INPUT_KEY, mobile_input)
	config.save(USER_PREFERENCES_FILE_NAME)
