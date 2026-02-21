## Checkpoint — Area2D
## When the player touches this, it becomes the respawn point for the current level.
## GameState stores the checkpoint position so reload_current_scene() respawns correctly.
extends Area2D

@export var checkpoint_id: int = 1  # Set unique ID per checkpoint in each level

var _activated: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Grey out if already passed this checkpoint
	if GameState.checkpoint_id >= checkpoint_id:
		_activate_visual()


func _on_body_entered(body: Node2D) -> void:
	if _activated or not body.is_in_group("player"):
		return
	if GameState.checkpoint_id >= checkpoint_id:
		return

	GameState.checkpoint_id = checkpoint_id
	GameState.checkpoint_position = global_position
	_activate_visual()


func _activate_visual() -> void:
	_activated = true
	if _sprite.sprite_frames.has_animation("active"):
		_sprite.play("active")
	modulate = Color(1.0, 0.8, 0.2, 1.0)  # Gold tint = activated
