extends Label

onready var _animation := $Animation as AnimationPlayer
const HIGHLIGHT_TEXT_ANIMATION := "highlight_text"


func _update_score(score: int):
	text = str(score)
	_animation.play("highlight_text")


func _on_PongGame_left_scored(score: int):
	_update_score(score)


func _on_PongGame_right_scored(score: int):
	_update_score(score)
