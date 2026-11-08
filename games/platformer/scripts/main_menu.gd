## MainMenu — Control
## Title screen. Start game resets state and loads Level 1.
extends Control

@onready var _start_button: Button = $VBoxContainer/StartButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton
@onready var _lives_label: Label = $VBoxContainer/LivesLabel
@onready var _high_score_label: Label = $VBoxContainer/HighScoreLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	if has_node("VBoxContainer/TacticsButton"):
		$VBoxContainer/TacticsButton.pressed.connect(_on_tactics_pressed)

	if has_node("VBoxContainer/BossArenaButton"):
		$VBoxContainer/BossArenaButton.pressed.connect(_on_boss_arena_pressed)

	if has_node("VBoxContainer/VerticalSliceButton"):
		$VBoxContainer/VerticalSliceButton.pressed.connect(_on_vertical_slice_pressed)

	if has_node("VBoxContainer/ToyboxButton"):
		$VBoxContainer/ToyboxButton.pressed.connect(_on_toybox_pressed)

	_high_score_label.text = "High Score: %d" % GameState.high_score

	# Show remaining lives if returning from a run (not a fresh game)
	if GameState.lives < 3:
		_lives_label.text = "Lives remaining: %d" % GameState.lives
		_lives_label.visible = true
	else:
		_lives_label.visible = false


func _on_tactics_pressed() -> void:
	get_tree().change_scene_to_file("res://games/tactics/scenes/tactical_grid_prototype.tscn")


func _on_boss_arena_pressed() -> void:
	get_tree().change_scene_to_file("res://games/tactics/scenes/boss_arena_prototype.tscn")


func _on_vertical_slice_pressed() -> void:
	get_tree().change_scene_to_file("res://games/tactics/scenes/vertical_slice_shrine.tscn")


func _on_start_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://games/platformer/scenes/level_1.tscn")


func _on_toybox_pressed() -> void:
	get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_menu.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()

