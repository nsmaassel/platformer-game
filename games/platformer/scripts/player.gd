## Player — CharacterBody2D
## Handles movement, jumping, animation, stomp attacks, and death.
## Requires input actions: move_left, move_right, jump (set in project.godot)
extends CharacterBody2D

const Telemetry = preload("res://shared/scripts/telemetry.gd")

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
var _is_dying: bool = false

var has_double_jump: bool = false
var _jumps_left: int = 1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _placeholder: Polygon2D = $Placeholder
@onready var _stomp_area: Area2D = $StompArea
@onready var _hurt_area: Area2D = $HurtArea
@onready var _camera: Camera2D = $Camera2D if has_node("Camera2D") else null

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


func setup_camera_limits(right_limit: int) -> void:
	if _camera != null:
		_camera.limit_left = 0
		_camera.limit_top = 0
		_camera.limit_bottom = 270
		_camera.limit_right = right_limit


func grant_powerup(type: String) -> void:
	if type == "double_jump":
		has_double_jump = true
		_jumps_left = 2
		_sprite.modulate = Color(1.2, 1.1, 0.8, 1.0)  # Golden tint when powered up


func _physics_process(delta: float) -> void:
	# Death hop processing
	if _is_dying:
		velocity.y += GRAVITY * delta
		position += velocity * delta
		if _has_sprites:
			_sprite.play("hurt")
		return

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
		_jumps_left = 2 if has_double_jump else 1
	else:
		_coyote_timer -= delta

	# Jump buffer counter — records a recent jump press
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer = JUMP_BUFFER_TIME

		# Mid-air double jump
		if not is_on_floor() and _coyote_timer <= 0.0 and _jumps_left > 0:
			velocity.y = JUMP_VELOCITY * 0.95
			_jumps_left -= 1
			_jump_buffer_timer = 0.0
			GameState.play_sfx("jump")
			Telemetry.log_event("PLAYER_DOUBLE_JUMP", "PLATFORMER", {"pos": [position.x, position.y]})
	else:
		_jump_buffer_timer -= delta

	# Ground / Coyote Jump
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = JUMP_VELOCITY
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		_jumps_left -= 1
		GameState.play_sfx("jump")
		Telemetry.log_event("PLAYER_JUMP", "PLATFORMER", {"pos": [position.x, position.y]})



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
	if _is_dying:
		return
	_is_dying = true
	GameState.play_sfx("hurt")
	GameState.lives -= 1
	if GameState.lives <= 0:
		GameState.reset()
		get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn")
	else:
		get_tree().reload_current_scene()


func _on_stomp(body: Node2D) -> void:
	if _is_dying:
		return
	# Stomp area is at player's feet — kill the enemy and bounce
	if body.has_method("stomp"):
		body.stomp()
		GameState.add_score(100)
		velocity.y = STOMP_BOUNCE
		Telemetry.log_event("ENEMY_STOMPED", "PLATFORMER", {"enemy": body.name, "score": GameState.score})


func _on_hurt(body: Node2D) -> void:
	if _invincible or _is_dying:
		return
	# Side/bottom contact with an enemy — take damage
	if body.is_in_group("enemy") or body.name.begins_with("Spike") or body.is_in_group("hazard"):
		_is_dying = true
		_invincible = true
		GameState.play_sfx("hurt")
		Telemetry.log_event("PLAYER_HURT", "PLATFORMER", {"hazard": body.name, "lives_remaining": GameState.lives - 1})

		# Disable collisions for death hop
		$CollisionShape2D.set_deferred("disabled", true)
		_stomp_area.set_deferred("monitoring", false)
		_hurt_area.set_deferred("monitoring", false)

		# Mario Death Hop: Pop up & fall off screen
		velocity.x = 0.0
		velocity.y = -240.0
		if _has_sprites:
			_sprite.play("hurt")

		GameState.lives -= 1

		await get_tree().create_timer(0.8).timeout

		if GameState.lives <= 0:
			GameState.reset()
			get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn")
		else:
			get_tree().reload_current_scene()
