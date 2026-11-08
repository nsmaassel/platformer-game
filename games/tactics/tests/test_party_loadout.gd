# games/tactics/tests/test_party_loadout.gd
## Unit test suite for PartyManager loadout and party management
extends RefCounted

const PARTY_MANAGER_PATHS := [
	"res://games/tactics/scripts/party_manager.gd"
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


func _get_party_manager() -> Object:
	for path in PARTY_MANAGER_PATHS:
		if ResourceLoader.exists(path):
			var script = load(path)
			if script != null:
				if script.has_method("new"):
					return script.new()
				return script

	_record_failure("PartyManager script does not exist at any expected path in res://games/tactics/scripts/")
	return null


## Specification 1: Asserts PartyManager.validate_party(party) returns true when party.size() == 3, and false otherwise.
func test_party_size_validation() -> void:
	var manager = _get_party_manager()
	if manager == null:
		return
	if not manager.has_method("validate_party"):
		_record_failure("PartyManager.validate_party is not implemented")
		return

	var party_valid = ["Sun Knight", "Pyromancer", "Frost Blade"]
	var party_too_small = ["Sun Knight", "Pyromancer"]
	var party_too_large = ["Sun Knight", "Pyromancer", "Frost Blade", "Ranger"]
	var party_empty = []

	var is_valid_3 = manager.call("validate_party", party_valid)
	assert_true(is_valid_3 == true, "validate_party should return true when party size is 3")

	var is_valid_2 = manager.call("validate_party", party_too_small)
	assert_true(is_valid_2 == false, "validate_party should return false when party size is 2")

	var is_valid_4 = manager.call("validate_party", party_too_large)
	assert_true(is_valid_4 == false, "validate_party should return false when party size is 4")

	var is_valid_0 = manager.call("validate_party", party_empty)
	assert_true(is_valid_0 == false, "validate_party should return false when party size is 0")


## Specification 2: Asserts PartyManager.apply_relic(unit_data, "EMBER_SIGIL") increases max_ap by 1,
## and apply_relic(unit_data, "WARDING_CHARM") increases max_hp by 5.
func test_relic_stat_modifiers() -> void:
	var manager = _get_party_manager()
	if manager == null:
		return
	if not manager.has_method("apply_relic"):
		_record_failure("PartyManager.apply_relic is not implemented")
		return

	var unit_data = {
		"id": "hero_1",
		"class": "Sun Knight",
		"max_ap": 4,
		"max_hp": 20
	}

	var initial_max_ap: int = unit_data["max_ap"]
	var result_sigil = manager.call("apply_relic", unit_data, "EMBER_SIGIL")
	var new_max_ap: int = unit_data.get("max_ap", initial_max_ap)
	if result_sigil is Dictionary and result_sigil.has("max_ap"):
		new_max_ap = result_sigil["max_ap"]

	assert_eq(
		new_max_ap,
		initial_max_ap + 1,
		"apply_relic with EMBER_SIGIL should increase max_ap by 1 (expected %d, got %d)" % [initial_max_ap + 1, new_max_ap]
	)

	var initial_max_hp: int = unit_data["max_hp"]
	var result_charm = manager.call("apply_relic", unit_data, "WARDING_CHARM")
	var new_max_hp: int = unit_data.get("max_hp", initial_max_hp)
	if result_charm is Dictionary and result_charm.has("max_hp"):
		new_max_hp = result_charm["max_hp"]

	assert_eq(
		new_max_hp,
		initial_max_hp + 5,
		"apply_relic with WARDING_CHARM should increase max_hp by 5 (expected %d, got %d)" % [initial_max_hp + 5, new_max_hp]
	)


## Specification 3: Asserts PartyManager.get_available_classes() returns an Array of 5 hero classes
## ("Sun Knight", "Pyromancer", "Frost Blade", "Ranger", "Cleric").
func test_default_hero_roster() -> void:
	var manager = _get_party_manager()
	if manager == null:
		return
	if not manager.has_method("get_available_classes"):
		_record_failure("PartyManager.get_available_classes is not implemented")
		return

	var hero_roster = manager.call("get_available_classes")
	assert_true(hero_roster is Array, "get_available_classes must return an Array")
	if not (hero_roster is Array):
		return

	var expected_classes = ["Sun Knight", "Pyromancer", "Frost Blade", "Ranger", "Cleric"]
	assert_eq(
		hero_roster.size(),
		5,
		"get_available_classes roster should contain exactly 5 elements"
	)

	for hero_class in expected_classes:
		assert_true(
			hero_roster.has(hero_class),
			"get_available_classes roster should contain class '%s'. Actual roster: %s" % [hero_class, str(hero_roster)]
		)
