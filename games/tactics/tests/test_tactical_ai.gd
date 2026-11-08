# games/tactics/tests/test_tactical_ai.gd
## Unit test suite for TacticalAI
extends RefCounted

const TACTICAL_AI_PATH := "res://games/tactics/scripts/tactics/tactical_ai.gd"
var errors: Array[String] = []


func _record_failure(msg: String) -> void:
	errors.append(msg)
	print("    ❌ FAILED: %s" % msg)


func assert_eq(actual, expected, message: String = "") -> bool:
	if actual != expected:
		var err := "Expected '%s', got '%s'. %s" % [str(expected), str(actual), message]
		_record_failure(err)
		return false
	return true


func assert_true(condition: bool, message: String = "") -> bool:
	if not condition:
		var err := "Condition is false. %s" % message
		_record_failure(err)
		return false
	return true


func _get_tactical_ai_script() -> Object:
	if not ResourceLoader.exists(TACTICAL_AI_PATH):
		_record_failure("TacticalAI script does not exist at %s" % TACTICAL_AI_PATH)
		return null
	var script = load(TACTICAL_AI_PATH)
	if script == null:
		_record_failure("Failed to load TacticalAI script at %s" % TACTICAL_AI_PATH)
		return null
	return script




## Specification 1: Asserts TacticalAI.calculate_path_weight_cost(path, terrain_weights)
## returns higher cost for paths containing 'LAVA' (weight 3.0) than pure 'DIRT' (weight 1.0).
func test_astar_terrain_weights() -> void:
	var tactical_ai = _get_tactical_ai_script()
	if tactical_ai == null:
		return
	if not tactical_ai.has_method("calculate_path_weight_cost"):
		_record_failure("TacticalAI.calculate_path_weight_cost is not implemented")
		return

	var terrain_weights = {"DIRT": 1.0, "LAVA": 3.0}
	var path_dirt = ["DIRT", "DIRT", "DIRT"]
	var path_lava = ["DIRT", "LAVA", "DIRT"]

	var cost_dirt = tactical_ai.call("calculate_path_weight_cost", path_dirt, terrain_weights)
	var cost_lava = tactical_ai.call("calculate_path_weight_cost", path_lava, terrain_weights)

	assert_true(
		cost_lava > cost_dirt,
		"Path containing LAVA (weight 3.0) should have higher cost than pure DIRT path (weight 1.0). Lava cost: %s, Dirt cost: %s" % [str(cost_lava), str(cost_dirt)]
	)


## Specification 2: Asserts TacticalAI.calculate_artillery_target_pos(enemy_pos, player_pos, board)
## selects a position at 4 tiles distance from player.
func test_artillery_ai_positioning() -> void:
	var tactical_ai = _get_tactical_ai_script()
	if tactical_ai == null:
		return
	if not tactical_ai.has_method("calculate_artillery_target_pos"):
		_record_failure("TacticalAI.calculate_artillery_target_pos is not implemented")
		return

	var enemy_pos = Vector2i(0, 0)
	var player_pos = Vector2i(10, 0)
	var board = null

	var target_pos = tactical_ai.call("calculate_artillery_target_pos", enemy_pos, player_pos, board)
	if target_pos == null:
		_record_failure("calculate_artillery_target_pos returned null")
		return

	var dist: float = 0.0
	if target_pos is Vector2i or target_pos is Vector2:
		dist = abs(target_pos.x - player_pos.x) + abs(target_pos.y - player_pos.y)
	elif target_pos is Dictionary and target_pos.has("x") and target_pos.has("y"):
		dist = abs(target_pos["x"] - player_pos["x"]) + abs(target_pos["y"] - player_pos["y"])
	else:
		_record_failure("calculate_artillery_target_pos returned invalid position format: %s" % str(target_pos))
		return

	assert_eq(
		dist,
		4.0,
		"Artillery target position should be at 4 tiles distance from player. Got distance: %s (target_pos: %s)" % [str(dist), str(target_pos)]
	)


## Specification 3: Asserts TacticalAI.get_boss_phase(current_hp, max_hp)
## returns "PHASE_2_ENRAGED" when current_hp <= max_hp / 2, and "PHASE_1_NORMAL" when current_hp > max_hp / 2.
func test_boss_titan_enrage() -> void:
	var tactical_ai = _get_tactical_ai_script()
	if tactical_ai == null:
		return
	if not tactical_ai.has_method("get_boss_phase"):
		_record_failure("TacticalAI.get_boss_phase is not implemented")
		return

	var max_hp = 100

	# Test current_hp <= max_hp / 2 -> PHASE_2_ENRAGED
	var hp_enraged = 50
	var phase_enraged = tactical_ai.call("get_boss_phase", hp_enraged, max_hp)
	assert_eq(
		phase_enraged,
		"PHASE_2_ENRAGED",
		"get_boss_phase should return PHASE_2_ENRAGED when current_hp (%d) <= max_hp / 2 (%d)" % [hp_enraged, max_hp / 2]
	)

	# Test current_hp > max_hp / 2 -> PHASE_1_NORMAL
	var hp_normal = 51
	var phase_normal = tactical_ai.call("get_boss_phase", hp_normal, max_hp)
	assert_eq(
		phase_normal,
		"PHASE_1_NORMAL",
		"get_boss_phase should return PHASE_1_NORMAL when current_hp (%d) > max_hp / 2 (%d)" % [hp_normal, max_hp / 2]
	)
