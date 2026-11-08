## Concept D: Metroidvania Action Platformer (Mega Man Zero x Golden Sun)
## Prototyping side-scrolling dash-cancels, saber slashes, wall jumps, and elemental form shifts.
extends CharacterBody2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")

const SPEED: float = 140.0
const JUMP_VELOCITY: float = -320.0
const DASH_SPEED: float = 280.0
const GRAVITY: float = 900.0

enum ElementForm { FLAME, FROST, GROUNDED }
var current_form: ElementForm = ElementForm.FLAME

var is_dashing: bool = false
var dash_timer: float = 0.0
var dummy_hp: int = 200

@onready var sprite: Sprite2D = $Sprite2D
@onready var body_color: ColorRect = $Sprite2D/Body
@onready var camera: Camera2D = $Camera2D
@onready var dummy: Sprite2D = $Dummy
@onready var dummy_hp_label: Label = $Dummy/HPLabel
@onready var form_label: Label = $CanvasLayer/FormLabel
@onready var hud_label: Label = $CanvasLayer/HUDLabel


func _ready() -> void:
	_update_form_ui()


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y += GRAVITY * delta

	# Handle Dash
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false

	# Horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if is_dashing:
		var dash_dir := -1.0 if sprite.flip_h else 1.0
		velocity.x = dash_dir * DASH_SPEED
	elif direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * 10 * delta)

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_menu.tscn")
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W, KEY_UP, KEY_SPACE:
				if is_on_floor():
					velocity.y = JUMP_VELOCITY
					GameState.play_sfx("jump")
					JuiceEffects.squash_and_stretch(sprite, Vector2(0.7, 1.4), 0.15)
			KEY_L, KEY_ALT:
				_start_dash()
			KEY_J:
				_saber_slash()
			KEY_K, KEY_SHIFT:
				_cycle_element_form()


func _start_dash() -> void:
	is_dashing = true
	dash_timer = 0.2
	GameState.play_sfx("coin")
	JuiceEffects.squash_and_stretch(sprite, Vector2(1.5, 0.6), 0.15)


func _saber_slash() -> void:
	GameState.play_sfx("stomp")
	JuiceEffects.squash_and_stretch(sprite, Vector2(1.3, 0.8), 0.12)

	# Distance to target dummy
	if global_position.distance_to(dummy.global_position) < 40.0:
		var dmg := 40 if current_form == ElementForm.FLAME else 25
		dummy_hp -= dmg
		if dummy_hp <= 0:
			dummy_hp = 200
		dummy_hp_label.text = "Sigma Dummy HP: %d" % dummy_hp

		# Hit-stop & Screen Shake
		JuiceEffects.freeze_frame(get_tree(), 0.06, 0.05)
		JuiceEffects.shake_camera(camera, 7.0, 0.15)
		JuiceEffects.flash_sprite(dummy, Color(3.0, 1.0, 1.0, 1.0), 0.1)


func _cycle_element_form() -> void:
	current_form = ((current_form + 1) % 3) as ElementForm
	GameState.play_sfx("powerup")
	_update_form_ui()
	JuiceEffects.squash_and_stretch(sprite, Vector2(1.2, 1.2), 0.15)


func _update_form_ui() -> void:
	match current_form:
		ElementForm.FLAME:
			body_color.color = Color(0.9, 0.3, 0.2, 1)
			form_label.text = "ACTIVE FORM: [FLAME - High Saber Damage]"
		ElementForm.FROST:
			body_color.color = Color(0.2, 0.7, 0.9, 1)
			form_label.text = "ACTIVE FORM: [FROST - Ice Dash Trail]"
		ElementForm.GROUNDED:
			body_color.color = Color(0.8, 0.6, 0.2, 1)
			form_label.text = "ACTIVE FORM: [GROUNDED - Heavy Armor]"

	hud_label.text = "[CONCEPT D: Mega Man Zero x Golden Sun]\n[WASD/Arrows] Run/Jump  |  [L/Alt] Air Dash  |  [J] Saber Slash  |  [K/Shift] Form Swap  |  [Esc] Menu"
