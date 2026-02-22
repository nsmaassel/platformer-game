## Slime — CharacterBody2D
## Patrols left and right until it hits a wall or ledge edge.
## Player kills it by jumping on top (stomp). Contact from side/below kills the player.
extends CharacterBody2D

const SPEED: float = 50.0
const GRAVITY: float = 980.0

var _direction: float = 1.0  # 1 = right, -1 = left

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _ledge_check: RayCast2D = $LedgeCheck


func _ready() -> void:
	add_to_group("enemy")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	velocity.x = _direction * SPEED

	# Reverse on wall collision
	if is_on_wall():
		_turn()

	# Reverse at ledge edge (ledge check ray points down-forward)
	if is_on_floor() and not _ledge_check.is_colliding():
		_turn()

	_sprite.flip_h = _direction < 0.0
	_sprite.play("walk")

	move_and_slide()


func _turn() -> void:
	_direction *= -1.0
	# Move the ledge check to always point ahead
	_ledge_check.position.x = absf(_ledge_check.position.x) * _direction


## Called by player's stomp detection area
func stomp() -> void:
	queue_free()
