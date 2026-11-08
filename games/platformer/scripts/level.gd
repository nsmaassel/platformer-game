## Level — attached to each level's root Node2D
## Updates the HUD with current game state each frame.
extends Node2D

@export var level_width: int = 1008

@onready var _lives_label: Label = $HUD/LivesLabel
@onready var _level_label: Label = $HUD/LevelLabel
@onready var _score_label: Label = $HUD/ScoreLabel if has_node("HUD/ScoreLabel") else null
@onready var _sky: ColorRect = $Sky if has_node("Sky") else null


func _ready() -> void:
	_level_label.text = "Level %d" % GameState.current_level
	if _sky:
		_sky.offset_right = float(level_width + 256)
		_sky.offset_bottom = 270.0

	var player := get_node_or_null("Player")
	if player != null and player.has_method("setup_camera_limits"):
		player.call("setup_camera_limits", level_width)


func _process(_delta: float) -> void:
	_lives_label.text = "Lives: %d" % GameState.lives
	if _score_label:
		_score_label.text = "Score: %d" % GameState.score

