# games/tactics/tests/test_campaign_flow.gd
## Unit test suite for CampaignManager campaign flow and progression
extends RefCounted

const CAMPAIGN_MANAGER_PATHS := [
	"res://games/tactics/scripts/campaign_manager.gd",
	"res://games/tactics/scripts/campaign/campaign_manager.gd",
	"res://games/tactics/scripts/campaign_flow.gd"
]

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


func _get_campaign_manager() -> Object:
	for path in CAMPAIGN_MANAGER_PATHS:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script != null:
				if script.has_method("new"):
					return script.new()
				return script

	_record_failure("CampaignManager script does not exist at any expected path in res://games/tactics/scripts/")
	return null


## Specification 1: Asserts CampaignManager.get_mission_list() returns an Array of 3 mission titles
## ("Outpost Ambush", "Lava Trench", "Golem Forge Siege").
func test_campaign_mission_list() -> void:
	var manager = _get_campaign_manager()
	if manager == null:
		return
	if not manager.has_method("get_mission_list"):
		_record_failure("CampaignManager.get_mission_list is not implemented")
		return

	var mission_list = manager.call("get_mission_list")
	assert_true(mission_list is Array, "get_mission_list must return an Array")
	if not (mission_list is Array):
		return

	var expected_missions = ["Outpost Ambush", "Lava Trench", "Golem Forge Siege"]
	assert_eq(
		mission_list.size(),
		3,
		"get_mission_list should return an Array of 3 mission titles"
	)

	for i in range(min(mission_list.size(), expected_missions.size())):
		assert_eq(
			mission_list[i],
			expected_missions[i],
			"Mission title at index %d should match '%s'" % [i, expected_missions[i]]
		)


## Specification 2: Asserts CampaignManager.unlock_next_mission(0) returns 1, and unlock_next_mission(1) returns 2.
func test_mission_unlock_progression() -> void:
	var manager = _get_campaign_manager()
	if manager == null:
		return
	if not manager.has_method("unlock_next_mission"):
		_record_failure("CampaignManager.unlock_next_mission is not implemented")
		return

	var next_m0 = manager.call("unlock_next_mission", 0)
	assert_eq(next_m0, 1, "unlock_next_mission(0) should return 1")

	var next_m1 = manager.call("unlock_next_mission", 1)
	assert_eq(next_m1, 2, "unlock_next_mission(1) should return 2")


## Specification 3: Asserts CampaignManager.evaluate_battle_outcome(3, 0) returns "VICTORY",
## and evaluate_battle_outcome(0, 2) returns "DEFEAT".
func test_campaign_victory_condition() -> void:
	var manager = _get_campaign_manager()
	if manager == null:
		return
	if not manager.has_method("evaluate_battle_outcome"):
		_record_failure("CampaignManager.evaluate_battle_outcome is not implemented")
		return

	var victory_result = manager.call("evaluate_battle_outcome", 3, 0)
	assert_eq(victory_result, "VICTORY", "evaluate_battle_outcome(3, 0) should return 'VICTORY'")

	var defeat_result = manager.call("evaluate_battle_outcome", 0, 2)
	assert_eq(defeat_result, "DEFEAT", "evaluate_battle_outcome(0, 2) should return 'DEFEAT'")
