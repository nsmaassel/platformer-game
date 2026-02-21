## MainMenu — Control
## Title screen. Start game resets state and loads Level 1.
extends Control

@onready var _start_button: Button = $VBoxContainer/StartButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton
@onready var _lives_label: Label = $VBoxContainer/LivesLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)

	# Show remaining lives if returning from a run (not a fresh game)
	if GameState.lives < 3:
		_lives_label.text = "Lives remaining: %d" % GameState.lives
		_lives_label.visible = true
	else:
		_lives_label.visible = false


func _on_start_pressed() -> void:
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/level_1.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
