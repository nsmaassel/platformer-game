## Coin — Area2D collectible
## Player collects on contact. +10 score, plays collect animation, then disappears.
extends Area2D

var _collected: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("coin")
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return
	_collected = true
	GameState.add_score(10)

	# Play collect animation if defined, then remove
	if _sprite.sprite_frames.has_animation("collect"):
		_sprite.play("collect")
		await _sprite.animation_finished
	queue_free()
