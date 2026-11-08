class_name TacticalAbilities
extends RefCounted

static func get_ability_highlights(board, ability: String, u_pos: Vector2i) -> Dictionary:
	var highlights = {}
	if ability == "FIREBALL":
		for y in range(-4, 5):
			for x in range(-4, 5):
				var target = u_pos + Vector2i(x, y)
				if board.is_valid_grid(target):
					highlights[target] = Color(1.0, 0.5, 0.1, 0.6)
	elif ability == "SHIELD_BASH":
		for y in range(-1, 2):
			for x in range(-1, 2):
				if abs(x) + abs(y) == 1:
					var target = u_pos + Vector2i(x, y)
					if board.is_valid_grid(target):
						highlights[target] = Color(0.7, 0.2, 0.9, 0.6)
	elif ability == "ICE_DASH":
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			for step in range(1, 5):
				var target = u_pos + dir * step
				if board.is_valid_grid(target):
					highlights[target] = Color(0.1, 0.9, 1.0, 0.6)
	elif ability == "PIERCING_SHOT":
		for dir in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			for step in range(1, 7):
				var target = u_pos + dir * step
				if board.is_valid_grid(target):
					highlights[target] = Color(1.0, 0.8, 0.1, 0.6)
	elif ability == "HEALING_LIGHT":
		for y in range(-1, 2):
			for x in range(-1, 2):
				var target = u_pos + Vector2i(x, y)
				if board.is_valid_grid(target):
					highlights[target] = Color(0.2, 1.0, 0.5, 0.6)
	return highlights
