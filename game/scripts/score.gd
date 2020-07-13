extends Label

onready var _animation := $Animation as AnimationPlayer
const HIGHLIGHT_TEXT_ANIMATION := "highlight_text"


func _increase_score():
	text = str(int(text) + 1)
	_animation.play("highlight_text")


func _on_Ball_left_scored():
	_increase_score()


func _on_Ball_right_scored():
	_increase_score()
