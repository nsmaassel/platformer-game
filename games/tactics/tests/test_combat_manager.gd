# games/tactics/tests/test_combat_manager.gd
## Unit test suite for CombatManager
extends RefCounted

const COMBAT_MANAGER_PATH := "res://games/tactics/scripts/combat_manager.gd"
var errors: Array[String] = []


func _record_failure(msg: String) -> void:
	errors.append(msg)
	print("    ❌ FAILED: %s" % msg)
	assert(false, msg)


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


func _get_combat_manager() -> Object:
	if not ResourceLoader.exists(COMBAT_MANAGER_PATH):
		_record_failure("CombatManager script does not exist at %s" % COMBAT_MANAGER_PATH)
		return null
	var script = load(COMBAT_MANAGER_PATH)
	if script == null:
		_record_failure("Failed to load CombatManager script at %s" % COMBAT_MANAGER_PATH)
		return null
	var instance = script.new()
	if instance == null:
		_record_failure("Failed to instantiate CombatManager from %s" % COMBAT_MANAGER_PATH)
		return null
	return instance


func test_start_player_turn() -> void:
	var manager = _get_combat_manager()
	if manager == null:
		return
	var unit = {"id": "hero_1", "ap": 0}
	var units = [unit]
	manager.start_player_turn(units)
	assert_eq(unit.get("ap", 0), 4, "start_player_turn should set unit 'ap' to 4")
	assert_eq(manager.get("phase"), "PLAYER_PHASE", "start_player_turn should set phase to 'PLAYER_PHASE'")


func test_calculate_move_ap_cost() -> void:
	var manager = _get_combat_manager()
	if manager == null:
		return
	var cost = manager.calculate_move_ap_cost(4)
	assert_eq(cost, 2, "Moving 4 tiles should cost 2 AP (1 AP per 2 cells)")


func test_calculate_attack_ap_cost() -> void:
	var manager = _get_combat_manager()
	if manager == null:
		return
	var cost = manager.calculate_attack_ap_cost()
	assert_eq(cost, 2, "Basic attack should cost 2 AP")


func test_end_turn() -> void:
	var manager = _get_combat_manager()
	if manager == null:
		return
	var unit = {"id": "hero_1", "ap": 0}
	manager.start_player_turn([unit])
	manager.end_turn()
	assert_eq(manager.get("phase"), "ENEMY_PHASE", "end_turn should transition phase to 'ENEMY_PHASE'")
