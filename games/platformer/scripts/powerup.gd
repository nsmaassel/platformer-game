## powerup.gd — Powerup Star Item
## Grants player Double Jump ability and +200 bonus score upon collection.
extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _collected: bool = false
var _float_time: float = 0.0
var _initial_y: float = 0.0


func _ready() -> void:
	_initial_y = position.y
	body_entered.connect(_on_body_entered)
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _process(delta: float) -> void:
	if _collected:
		return
	_float_time += delta * 3.0
	position.y = _initial_y + sin(_float_time) * 3.0


func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("player") or body.name == "Player":
		_collected = true
		GameState.add_score(200)
		GameState.play_sfx("powerup")
		const Telemetry = preload("res://shared/scripts/telemetry.gd")
		Telemetry.log_event("POWERUP_COLLECTED", "PLATFORMER", {"type": "double_jump", "score": GameState.score})
		if body.has_method("grant_powerup"):
			body.call("grant_powerup", "double_jump")
		queue_free()
