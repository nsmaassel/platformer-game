## Goal — Area2D
## Level completion trigger. When the player enters this area,
## load the next level or return to main menu if there are no more levels.
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	const Telemetry = preload("res://shared/scripts/telemetry.gd")
	Telemetry.log_event("LEVEL_COMPLETE", "PLATFORMER", {"level": GameState.current_level, "score": GameState.score})

	GameState.play_sfx("win")
	GameState.current_level += 1
	GameState.unlock_level(GameState.current_level)
	GameState.clear_checkpoint()  # Fresh start on the new level
	var next_scene := "res://games/platformer/scenes/level_%d.tscn" % GameState.current_level

	if ResourceLoader.exists(next_scene):
		get_tree().change_scene_to_file(next_scene)
	else:
		# All levels complete — go back to menu with high score
		get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn")
