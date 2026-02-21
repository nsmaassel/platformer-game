## Level — attached to each level's root Node2D
## Updates the HUD with current game state.
extends Node2D

@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _level_label: Label = $HUD/LevelLabel


func _ready() -> void:
	_lives_label.text = "Lives: %d" % GameState.lives
	_level_label.text = "Level %d" % GameState.current_level
