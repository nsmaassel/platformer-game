## Concept A: Top-Down Action RPG (Zelda x Golden Sun)
## Prototyping 8-way movement, sword attack with hit-stop, and Psynergy spell environmental interaction.
extends Node2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")



@export var move_speed: float = 120.0

@onready var player: Sprite2D = $Player
@onready var camera: Camera2D = $Camera2D
@onready var dummy: Sprite2D = $Dummy
@onready var dummy_label: Label = $Dummy/Label
@onready var torch: Sprite2D = $Torch
@onready var torch_label: Label = $Torch/Label
@onready var hud_label: Label = $CanvasLayer/HUDLabel

var dummy_hp: int = 50
var torch_lit: bool = false
var is_attacking: bool = false


func _ready() -> void:
	_update_hud()


func _physics_process(delta: float) -> void:
	var input_vec := Vector2.ZERO
	input_vec.x = Input.get_axis("move_left", "move_right")
	if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		input_vec.y = Input.get_axis("move_up", "move_down")
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			input_vec.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			input_vec.y += 1.0

	if input_vec.length() > 0:
		input_vec = input_vec.normalized()
		player.position += input_vec * move_speed * delta
		player.position.x = clamp(player.position.x, 20, 460)
		player.position.y = clamp(player.position.y, 40, 250)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_menu.tscn")
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_J or event.keycode == KEY_SPACE:
			_perform_sword_slash()
		elif event.keycode == KEY_K or event.keycode == KEY_SHIFT:
			_cast_psynergy_fire()


func _perform_sword_slash() -> void:
	if is_attacking:
		return
	is_attacking = true
	GameState.play_sfx("stomp")

	# Squash & Stretch on attack
	JuiceEffects.squash_and_stretch(player, Vector2(1.3, 0.7), 0.12)

	# Check distance to Dummy
	if player.position.distance_to(dummy.position) < 36.0:
		dummy_hp -= 10
		if dummy_hp <= 0:
			dummy_hp = 50
		dummy_label.text = "Dummy HP: %d" % dummy_hp

		# Trigger Hit-Stop, Screen Shake, and Sprite Flash
		JuiceEffects.freeze_frame(get_tree(), 0.06, 0.05)
		JuiceEffects.shake_camera(camera, 5.0, 0.15)
		JuiceEffects.flash_sprite(dummy, Color(3.0, 0.5, 0.5, 1.0), 0.1)

	await get_tree().create_timer(0.15).timeout
	is_attacking = false
	_update_hud()


func _cast_psynergy_fire() -> void:
	GameState.play_sfx("powerup")
	JuiceEffects.squash_and_stretch(player, Vector2(0.8, 1.4), 0.15)

	# Check distance to Torch puzzle interactable
	if player.position.distance_to(torch.position) < 50.0:
		torch_lit = !torch_lit
		torch.modulate = Color(2.5, 1.5, 0.4, 1.0) if torch_lit else Color(0.4, 0.4, 0.4, 1.0)
		torch_label.text = "Torch: LIT!" if torch_lit else "Torch: Unlit"
		JuiceEffects.flash_sprite(torch, Color(3.0, 2.0, 1.0, 1.0), 0.2)
		JuiceEffects.shake_camera(camera, 3.0, 0.1)

	_update_hud()


func _update_hud() -> void:
	hud_label.text = "[CONCEPT A: Zelda x Golden Sun]\n[WASD/Arrows] Move  |  [J/Space] Sword Slash  |  [K/Shift] Fire Psynergy  |  [Esc] Toybox Menu"
