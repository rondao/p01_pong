extends Label

onready var _animation := $Animation as AnimationPlayer
const HIGHLIGHT_TEXT_ANIMATION := "highlight_text"


func update_score(score: int):
	text = str(score)
	_animation.play("highlight_text")
