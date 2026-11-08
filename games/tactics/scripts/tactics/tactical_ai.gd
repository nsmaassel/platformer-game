class_name TacticalAI
extends RefCounted


static func calculate_enemy_move(enemy: Dictionary, active_units: Array, board) -> Dictionary:
	var result = {"move_pos": enemy["pos"], "attack_target": {}}
	if enemy.get("hp", 0) <= 0:
		return result
	
	var closest_player: Dictionary = {}
	var min_dist: float = 999.0
	for target in active_units:
		if target.get("team") == "PLAYER" and target.get("hp", 0) > 0:
			var dist = enemy["pos"].distance_to(target["pos"])
			if dist < min_dist:
				min_dist = dist
				closest_player = target
	
	if not closest_player.is_empty():
		board.update_astar_units(active_units, "ENEMY")
		board.astar_grid.set_point_solid(closest_player["pos"], false)
		var path = board.astar_grid.get_id_path(enemy["pos"], closest_player["pos"])
		if path.size() > 1:
			var move_steps = min(path.size() - 2, enemy.get("move_range", 3))
			if move_steps > 0:
				var next_pos = path[move_steps]
				var occupied = active_units.any(func(u): return u["pos"] == next_pos and u.get("hp", 0) > 0)
				if not occupied:
					result["move_pos"] = next_pos
					
		var test_pos = result["move_pos"]
		var dist_to_target = abs(test_pos.x - closest_player["pos"].x) + abs(test_pos.y - closest_player["pos"].y)
		if dist_to_target <= enemy.get("atk_range", 1) and board.has_line_of_sight(test_pos, closest_player["pos"]):
			result["attack_target"] = closest_player
			
	return result


static func calculate_path_weight_cost(path: Array, terrain_weights: Dictionary) -> float:
	var total_cost: float = 0.0
	for pos in path:
		total_cost += float(terrain_weights.get(pos, 1.0))
	return total_cost


static func calculate_artillery_target_pos(enemy_pos: Vector2i, player_pos: Vector2i, board) -> Vector2i:
	var best_pos: Vector2i = player_pos + Vector2i(4, 0)
	var min_dist: float = 999999.0

	for dx in range(-4, 5):
		var dy_abs = 4 - abs(dx)
		var dys = [dy_abs, -dy_abs] if dy_abs != 0 else [0]
		for dy in dys:
			var candidate = player_pos + Vector2i(dx, dy)
			if board != null and board.has_method("is_valid_grid"):
				if not board.is_valid_grid(candidate):
					continue
			var dist = Vector2(candidate).distance_to(Vector2(enemy_pos))
			if dist < min_dist:
				min_dist = dist
				best_pos = candidate

	return best_pos


static func get_boss_phase(current_hp: int, max_hp: int) -> String:
	if current_hp <= max_hp / 2:
		return "PHASE_2_ENRAGED"
	return "PHASE_1_NORMAL"



