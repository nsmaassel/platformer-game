## GameState — global autoload singleton
## Tracks lives, score, current level, and checkpoint across scenes.
## Access from anywhere: GameState.lives, GameState.score, etc.
extends Node

var lives: int = 3
var score: int = 0
var current_level: int = 1

# Checkpoint: set by Checkpoint nodes, cleared on level complete / game reset
var checkpoint_id: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO


func reset() -> void:
	lives = 3
	score = 0
	current_level = 1
	checkpoint_id = 0
	checkpoint_position = Vector2.ZERO


func clear_checkpoint() -> void:
	checkpoint_id = 0
	checkpoint_position = Vector2.ZERO


func add_score(points: int) -> void:
	score += points
