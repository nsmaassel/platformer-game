class_name CombatManager
extends RefCounted

signal phase_changed(new_phase: String)
signal ap_updated(unit_id: String, new_ap: int)

const PLAYER_PHASE: String = "PLAYER_PHASE"
const ENEMY_PHASE: String = "ENEMY_PHASE"

var current_phase: String = PLAYER_PHASE
var phase: String:
	get:
		return current_phase
	set(value):
		current_phase = value


func start_player_turn(units: Array) -> void:
	current_phase = PLAYER_PHASE
	for unit in units:
		if unit is Dictionary:
			unit["ap"] = 4
			var unit_id: String = str(unit.get("id", ""))
			ap_updated.emit(unit_id, 4)
		elif unit is Object:
			unit.set("ap", 4)
			var unit_id: String = str(unit.get("id")) if "id" in unit else ""
			ap_updated.emit(unit_id, 4)
	phase_changed.emit(PLAYER_PHASE)


func calculate_move_ap_cost(distance_cells: int) -> int:
	return int(ceil(distance_cells / 2.0))


func calculate_attack_ap_cost() -> int:
	return 2


func end_turn() -> void:
	current_phase = ENEMY_PHASE
	phase_changed.emit(ENEMY_PHASE)
