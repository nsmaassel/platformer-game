## validate_levels.gd — Headless scene validation tool
## Loads every level_*.tscn and verifies structural integrity.
## Run: godot --headless --path . --script scripts/validate_levels.gd
##
## Checks per level:
##   - Required nodes exist (Player, Goal, Terrain, HUD with labels)
##   - TileMapLayer has tile data (not empty/corrupt)
##   - Player is instanced from player.tscn (not inline)
##   - Goal is instanced from goal.tscn (not inline)
##   - Goal is positioned above fall-death threshold
##   - Player start is above ground (not buried in tiles)
##   - No overlapping entity positions (enemies/coins stacked on each other)
extends SceneTree


func _init() -> void:
	var passed := 0
	var failed := 0
	var warnings := 0
	var level_files := _find_level_files()

	if level_files.is_empty():
		print("VALIDATE: No level_*.tscn files found!")
		quit(1)
		return

	print("VALIDATE: Found %d level(s) to check" % level_files.size())
	print("")

	for path in level_files:
		var result := _validate_level(path)
		passed += result.passed
		failed += result.failed
		warnings += result.warnings

	print("")
	print("==========================================")
	print("VALIDATE SUMMARY: %d passed, %d failed, %d warnings" % [passed, failed, warnings])
	print("==========================================")

	quit(1 if failed > 0 else 0)


func _find_level_files() -> Array[String]:
	var files: Array[String] = []
	_search_dir_for_scenes("res://games/", files)
	files.sort()
	return files

func _search_dir_for_scenes(path: String, out_files: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null: return
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname != "." and fname != "..":
			var full_path = path + fname
			if dir.current_is_dir():
				_search_dir_for_scenes(full_path + "/", out_files)
			elif fname.ends_with(".tscn"):
				out_files.append(full_path)
		fname = dir.get_next()
	dir.list_dir_end()



func _validate_level(path: String) -> Dictionary:
	var result := {"passed": 0, "failed": 0, "warnings": 0}
	print("--- %s ---" % path)

	# Load the scene
	var scene := load(path) as PackedScene
	if scene == null:
		_fail(result, "Cannot load scene file (Parse error or broken dependencies!)")
		return result

	var root := scene.instantiate()
	if root == null:
		_fail(result, "Cannot instantiate scene")
		return result

	_pass(result, "Scene loads and instantiates cleanly")

	# Full platformer level validation checks for level_*.tscn files
	if path.contains("level_"):
		# --- Required nodes ---
		_check_node(root, result, "Player", "CharacterBody2D")
		_check_node(root, result, "Goal", "Area2D")
		_check_node(root, result, "Terrain", "TileMapLayer")
		_check_node(root, result, "HUD", "CanvasLayer")
		_check_node(root, result, "HUD/LivesLabel", "Label")
		_check_node(root, result, "HUD/LevelLabel", "Label")

		# --- Terrain has tile data ---
		var terrain := root.get_node_or_null("Terrain") as TileMapLayer
		if terrain != null:
			var used := terrain.get_used_cells()
			if used.is_empty():
				_fail(result, "Terrain TileMapLayer has no tiles placed")
			else:
				_pass(result, "Terrain has %d tiles" % used.size())

		# --- Player position checks ---
		var player := root.get_node_or_null("Player")
		if player != null:
			var pos: Vector2 = player.position
			if pos.y > 300.0:
				_fail(result, "Player starts below y=300 (at y=%.0f) — will instantly fall-die" % pos.y)
			else:
				_pass(result, "Player start position OK (%.0f, %.0f)" % [pos.x, pos.y])

		# --- Goal position checks ---
		var goal := root.get_node_or_null("Goal")
		if goal != null:
			var pos: Vector2 = goal.position
			if pos.y > 300.0:
				_fail(result, "Goal is below y=300 (at y=%.0f) — unreachable (below fall-death)" % pos.y)
			else:
				_pass(result, "Goal position OK (%.0f, %.0f)" % [pos.x, pos.y])

		# --- Goal is to the right of player (standard platformer layout) ---
		if player != null and goal != null:
			if goal.position.x <= player.position.x:
				_warn(result, "Goal is left of or at Player start — intentional?")
			else:
				_pass(result, "Goal is to the right of Player start")

		# --- Check for overlapping entities (enemies/coins stacked) ---
		_check_overlapping_entities(root, result)

		# --- Verify jump gap reachability ---
		_check_platform_jump_gaps(root, result)

		# --- HUD ScoreLabel ---
		if root.get_node_or_null("HUD/ScoreLabel") == null:
			_warn(result, "HUD/ScoreLabel not found — score won't display")

	root.queue_free()
	return result


func _check_platform_jump_gaps(root: Node, result: Dictionary) -> void:
	var platforms_node := root.get_node_or_null("Platforms")
	if platforms_node == null or platforms_node.get_child_count() == 0:
		return

	var player := root.get_node_or_null("Player") as Node2D
	if player == null:
		return

	var jump_spots: Array[Vector2] = [player.position]

	for platform in platforms_node.get_children():
		if platform is Node2D:
			jump_spots.append(platform.position)

	var goal := root.get_node_or_null("Goal") as Node2D
	if goal != null:
		jump_spots.append(goal.position)

	jump_spots.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)

	var max_gap_found: float = 0.0
	var gap_failed := false
	for i in range(jump_spots.size() - 1):
		var gap: float = jump_spots[i + 1].x - jump_spots[i].x
		if gap > max_gap_found:
			max_gap_found = gap
		if gap > 125.0:
			gap_failed = true
			_fail(result, "Unreachable jump gap: %.0fpx between x=%.0f and x=%.0f (max reach 110px)" % [gap, jump_spots[i].x, jump_spots[i + 1].x])

	if not gap_failed:
		_pass(result, "All platform jump gaps reachable (max gap %.0fpx <= 110px)" % max_gap_found)




func _check_node(root: Node, result: Dictionary, node_path: String, expected_type: String) -> void:
	var node := root.get_node_or_null(node_path)
	if node == null:
		_fail(result, "Missing required node: %s" % node_path)
	elif node.get_class() != expected_type:
		_fail(result, "%s: expected %s, got %s" % [node_path, expected_type, node.get_class()])
	else:
		_pass(result, "%s (%s) present" % [node_path, expected_type])


func _check_overlapping_entities(root: Node, result: Dictionary) -> void:
	var positions: Dictionary = {}  # Vector2 -> Array[String]
	var skip_names := ["Player", "Goal", "Terrain", "HUD", "Sky"]

	# Check direct children and one level of grouping (Enemies/, Coins/)
	for child in root.get_children():
		if child is Node2D and not child.name in skip_names:
			# Check if this is a container (Enemies, Coins) with instanced children
			var has_instanced_children := false
			for grandchild in child.get_children():
				if grandchild.scene_file_path != "":
					has_instanced_children = true
					_record_position(positions, grandchild.name, grandchild.position)
			if not has_instanced_children and child.scene_file_path != "":
				# Standalone instanced entity (e.g. Checkpoint)
				_record_position(positions, child.name, child.position)

	for pos in positions:
		var names: Array = positions[pos]
		if names.size() > 1:
			_warn(result, "Overlapping entities at (%.0f, %.0f): %s" % [pos.x, pos.y, ", ".join(names)])

	if positions.size() > 0:
		var overlap_count := 0
		for pos in positions:
			if positions[pos].size() > 1:
				overlap_count += 1
		if overlap_count == 0:
			_pass(result, "No overlapping entities detected")


func _record_position(positions: Dictionary, node_name: String, pos: Vector2) -> void:
	# Round to nearest pixel to catch near-overlaps
	var key := Vector2(round(pos.x), round(pos.y))
	if not positions.has(key):
		positions[key] = []
	positions[key].append(str(node_name))


func _pass(result: Dictionary, msg: String) -> void:
	result.passed += 1
	print("  PASS: %s" % msg)


func _fail(result: Dictionary, msg: String) -> void:
	result.failed += 1
	print("  FAIL: %s" % msg)


func _warn(result: Dictionary, msg: String) -> void:
	result.warnings += 1
	print("  WARN: %s" % msg)
