## Telemetry — Global Game Observability & Analytics Logger
## Records structured JSON telemetry events for automated playtests, metrics, and debugging.
class_name Telemetry
extends RefCounted

const LOG_PATH: String = "res://logs/gameplay_telemetry.jsonl"
static var _events: Array[Dictionary] = []
static var _enabled: bool = true


## Logs a structured gameplay event with optional metadata
static func log_event(event_name: String, category: String = "GENERAL", payload: Dictionary = {}) -> void:
	if not _enabled:
		return

	var timestamp := Time.get_datetime_string_from_system()
	var entry := {
		"timestamp": timestamp,
		"event": event_name,
		"category": category,
		"payload": payload
	}
	_events.append(entry)

	# Print to stdout for CLI / test runner visibility
	print("📊 [%s] (%s) %s -> %s" % [timestamp, category, event_name, str(payload)])

	# Persist to jsonl file
	_append_to_file(entry)


static func get_events(filter_category: String = "") -> Array[Dictionary]:
	if filter_category == "":
		return _events.duplicate()
	var filtered: Array[Dictionary] = []
	for e in _events:
		if e.get("category", "") == filter_category:
			filtered.append(e)
	return filtered


static func count_event(event_name: String) -> int:
	var count := 0
	for e in _events:
		if e.get("event", "") == event_name:
			count += 1
	return count


static func has_event(event_name: String) -> bool:
	return count_event(event_name) > 0


static func clear() -> void:
	_events.clear()


static func _append_to_file(entry: Dictionary) -> void:
	var global_path := ProjectSettings.globalize_path(LOG_PATH)
	var dir_path := global_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file := FileAccess.open(global_path, FileAccess.READ_WRITE if FileAccess.file_exists(global_path) else FileAccess.WRITE)
	if file != null:
		file.seek_end()
		file.store_line(JSON.stringify(entry))
		file.close()
