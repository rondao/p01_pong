extends Node2D


func _ready():
	var arguments := OS.get_cmdline_args()

	for argument in arguments:
		if argument == "-match_maker":
			MatchMaker.start_match_maker()
			queue_free()
			return

	# If we get here, then there was no "-match_maker" args.
	get_tree().change_scene("res://src/main_menu/main_menu.tscn")
	queue_free()
