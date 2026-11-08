class_name PartyManager
extends RefCounted

## Manages party loadouts: the hero roster, party-size validation and relic stat bonuses.


static func get_available_classes() -> Array:
	return ["Sun Knight", "Pyromancer", "Frost Blade", "Ranger", "Cleric"]


static func validate_party(party: Array) -> bool:
	return party.size() == 3


static func apply_relic(unit_data: Dictionary, relic_id: String) -> Dictionary:
	match relic_id:
		"EMBER_SIGIL":
			unit_data["max_ap"] = unit_data.get("max_ap", 0) + 1
		"WARDING_CHARM":
			unit_data["max_hp"] = unit_data.get("max_hp", 0) + 5
	return unit_data
