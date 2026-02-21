## Player — CharacterBody2D
## Handles movement, jumping, animation, stomp attacks, and death.
## Requires input actions: move_left, move_right, jump (set in project.godot)
extends CharacterBody2D

# Tuning constants — adjust these to change game feel
const SPEED: float = 150.0
const JUMP_VELOCITY: float = -360.0
const GRAVITY: float = 980.0
const STOMP_BOUNCE: float = -240.0  # smaller bounce after stomping an enemy

# Coyote time: allows jumping briefly after walking off a ledge
const COYOTE_TIME: float = 0.12
# Jump buffer: queues a jump if button pressed just before landing
const JUMP_BUFFER_TIME: float = 0.12

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _invincible: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _placeholder: Polygon2D = $Placeholder
@onready var _stomp_area: Area2D = $StompArea
@onready var _hurt_area: Area2D = $HurtArea

var _has_sprites: bool = false


func _ready() -> void:
	add_to_group("player")
	_stomp_area.body_entered.connect(_on_stomp)
	_hurt_area.body_entered.connect(_on_hurt)

	# Use real sprites if any frames are loaded, otherwise show placeholder
	_has_sprites = _sprite.sprite_frames != null and _sprite.sprite_frames.get_animation_names().size() > 0 and _sprite.sprite_frames.get_frame_count("idle") > 0
	_sprite.visible = _has_sprites
	_placeholder.visible = not _has_sprites

	# Respawn at checkpoint if one was set
	if GameState.checkpoint_position != Vector2.ZERO:
		global_position = GameState.checkpoint_position


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
	if not _has_sprites:
		# Flip placeholder to face direction
		_placeholder.scale.x = -1.0 if _sprite.flip_h else 1.0
		return
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


func _on_stomp(body: Node2D) -> void:
	# Stomp area is at player's feet — kill the enemy and bounce
	if body.has_method("stomp"):
		body.stomp()
		GameState.add_score(100)
		velocity.y = STOMP_BOUNCE


func _on_hurt(body: Node2D) -> void:
	# Side/bottom contact with an enemy — take damage
	if _invincible:
		return
	if body.is_in_group("enemy"):
		_invincible = true
		GameState.lives -= 1
		if GameState.lives <= 0:
			GameState.reset()
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		else:
			# Brief knockback then reload
			await get_tree().create_timer(0.5).timeout
			get_tree().reload_current_scene()
