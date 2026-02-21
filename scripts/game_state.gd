## GameState — global autoload singleton
## Tracks lives, score, and current level across scenes.
## Access from anywhere: GameState.lives, GameState.score, etc.
extends Node

var lives: int = 3
var score: int = 0
var current_level: int = 1


func reset() -> void:
	lives = 3
	score = 0
	current_level = 1


func add_score(points: int) -> void:
	score += points
