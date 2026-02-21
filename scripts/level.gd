## Level — attached to each level's root Node2D
## Updates the HUD with current game state each frame.
extends Node2D

@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _level_label: Label = $HUD/LevelLabel
@onready var _score_label: Label = $HUD/ScoreLabel if has_node("HUD/ScoreLabel") else null


func _ready() -> void:
	_level_label.text = "Level %d" % GameState.current_level


func _process(_delta: float) -> void:
	_lives_label.text = "Lives: %d" % GameState.lives
	if _score_label:
		_score_label.text = "Score: %d" % GameState.score
