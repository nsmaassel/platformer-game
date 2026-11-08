## Spike — Area2D hazard
## Inflicts damage on contact with the player.
extends Area2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("_on_hurt"):
		body._on_hurt(self)
