extends Node
class_name Globals

enum Side {NONE = -1, LEFT = 0, RIGHT = 1}

enum GameInput {NONE = 0, UP = 1, DOWN = 2, CHARGE = 4}


static func opposite_side(side: int) -> int:
	return Side.RIGHT if side == Side.LEFT else Side.LEFT
