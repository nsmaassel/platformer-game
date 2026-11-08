# games/tactics/scripts/campaign_manager.gd
class_name CampaignManager
extends RefCounted


static func get_mission_list() -> Array:
	return ["Outpost Ambush", "Lava Trench", "Golem Forge Siege"]


static func unlock_next_mission(current_index: int) -> int:
	return min(current_index + 1, 2)


static func evaluate_battle_outcome(player_units_alive: int, enemy_units_alive: int) -> String:
	if enemy_units_alive == 0 and player_units_alive > 0:
		return "VICTORY"
	elif player_units_alive == 0:
		return "DEFEAT"
	return "ONGOING"
