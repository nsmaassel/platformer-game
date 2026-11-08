## Checkpoint — Area2D
## When the player touches this, it becomes the respawn point for the current level.
## GameState stores the checkpoint position so reload_current_scene() respawns correctly.
extends Area2D

@export var checkpoint_id: int = 1  # Set unique ID per checkpoint in each level

var _activated: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _pole: Polygon2D = get_node_or_null("Pole")
@onready var _flag: Polygon2D = get_node_or_null("Flag")

var _has_sprites: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)

	_has_sprites = _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("idle") and _sprite.sprite_frames.get_frame_count("idle") > 0
	_sprite.visible = _has_sprites
	if _pole != null:
		_pole.visible = not _has_sprites
	if _flag != null:
		_flag.visible = not _has_sprites

	# Grey out if already passed this checkpoint
	if GameState.checkpoint_id >= checkpoint_id:
		_activate_visual()
	else:
		if _has_sprites:
			_sprite.play("idle")


func _on_body_entered(body: Node2D) -> void:
	if _activated or not body.is_in_group("player"):
		return
	if GameState.checkpoint_id >= checkpoint_id:
		return

	GameState.checkpoint_id = checkpoint_id
	GameState.checkpoint_position = global_position
	GameState.play_sfx("checkpoint")
	const Telemetry = preload("res://shared/scripts/telemetry.gd")
	Telemetry.log_event("CHECKPOINT_TRIGGERED", "PLATFORMER", {"checkpoint_id": checkpoint_id, "pos": [global_position.x, global_position.y]})
	_activate_visual()



func _activate_visual() -> void:
	_activated = true
	if _has_sprites and _sprite.sprite_frames.has_animation("active"):
		_sprite.play("active")
		modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		modulate = Color(1.0, 0.8, 0.2, 1.0)  # Gold tint = activated fallback

