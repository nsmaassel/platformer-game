## GameState — global autoload singleton
## Tracks lives, score, current level, checkpoint, audio playback, and save/load persistence.
## Access from anywhere: GameState.lives, GameState.score, GameState.play_sfx("coin"), etc.
extends Node

const SAVE_PATH: String = "user://savegame.cfg"

var lives: int = 3
var score: int = 0
var high_score: int = 0
var current_level: int = 1
var max_level_unlocked: int = 1

# Checkpoint state
var checkpoint_id: int = 0
var checkpoint_position: Vector2 = Vector2.ZERO

# SFX Audio Stream Dictionary & Player Pool
var _sfx_streams: Dictionary = {}
var _audio_players: Array[AudioStreamPlayer] = []
const POOL_SIZE: int = 8
var _pool_index: int = 0


func _ready() -> void:
	_load_sfx_streams()
	_setup_audio_pool()
	load_game()


func _load_sfx_streams() -> void:
	var sfx_files := ["jump", "coin", "stomp", "checkpoint", "hurt", "win", "powerup", "hit", "laser", "explosion"]
	for sfx in sfx_files:
		var path := "res://assets/sfx/%s.wav" % sfx
		if ResourceLoader.exists(path):
			_sfx_streams[sfx] = load(path)



func _setup_audio_pool() -> void:
	for i in range(POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.bus = &"Master"
		add_child(player)
		_audio_players.append(player)


func play_sfx(sfx_name: String) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	var stream: AudioStream = _sfx_streams[sfx_name]
	if stream == null:
		return

	var player := _audio_players[_pool_index]
	_pool_index = (_pool_index + 1) % POOL_SIZE
	player.stream = stream
	player.play()


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
	if score > high_score:
		high_score = score
		save_game()


func unlock_level(level_num: int) -> void:
	if level_num > max_level_unlocked:
		max_level_unlocked = level_num
		save_game()


func save_game() -> void:
	var config := ConfigFile.new()
	config.set_value("progress", "high_score", high_score)
	config.set_value("progress", "max_level_unlocked", max_level_unlocked)
	config.save(SAVE_PATH)


func load_game() -> void:
	var config := ConfigFile.new()
	var err := config.load(SAVE_PATH)
	if err == OK:
		high_score = config.get_value("progress", "high_score", 0)
		max_level_unlocked = config.get_value("progress", "max_level_unlocked", 1)

