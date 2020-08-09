extends Node

const USER_PREFERENCES_FILE_NAME := "user://user_preferences.cfg"

const INPUT_SECTION := "input"
const PADDLE_TYPE_KEY := "paddle_type"

var config: ConfigFile

var paddle_type: int = Globals.PaddleType.NONE


func _ready():
	config = ConfigFile.new()

	if config.load(USER_PREFERENCES_FILE_NAME) == OK:
		paddle_type = config.get_value(INPUT_SECTION, PADDLE_TYPE_KEY)


func save_paddle_type(new_paddle_type: int):
	paddle_type = new_paddle_type

	config.set_value(INPUT_SECTION, PADDLE_TYPE_KEY, paddle_type)
# warning-ignore:return_value_discarded
	config.save(USER_PREFERENCES_FILE_NAME)
