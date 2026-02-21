## Player — CharacterBody2D
## Handles movement, jumping, animation, and death.
## Requires input actions: move_left, move_right, jump (set in project.godot)
extends CharacterBody2D

# Tuning constants — adjust these to change game feel
const SPEED: float = 150.0
const JUMP_VELOCITY: float = -360.0
const GRAVITY: float = 980.0

# Coyote time: allows jumping briefly after walking off a ledge
const COYOTE_TIME: float = 0.12
# Jump buffer: queues a jump if button pressed just before landing
const JUMP_BUFFER_TIME: float = 0.12

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	# Fall death — respawn if player drops below level
	if position.y > 320.0:
		_die()
		return

	# Apply gravity when airborne
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Coyote time counter — ticks down when in the air
	if is_on_floor():
		_coyote_timer = COYOTE_TIME
	else:
		_coyote_timer -= delta

	# Jump buffer counter — records a recent jump press
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		_jump_buffer_timer -= delta

	# Consume both timers to perform a jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# Flip sprite to face movement direction
	if direction != 0.0:
		_sprite.flip_h = direction < 0.0

	# Update animation
	_update_animation()

	move_and_slide()


func _update_animation() -> void:
	if not is_on_floor():
		if velocity.y < 0.0:
			_sprite.play("jump")
		else:
			_sprite.play("fall")
	elif absf(velocity.x) > 10.0:
		_sprite.play("run")
	else:
		_sprite.play("idle")


func _die() -> void:
	GameState.lives -= 1
	if GameState.lives <= 0:
		GameState.reset()
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		get_tree().reload_current_scene()
