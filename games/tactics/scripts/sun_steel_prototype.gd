## Sun & Steel Prototype — Flagship Action RPG Prototype
## Features: Fire Emblem Class Promotions, Golden Sun Spirit Gems/Overworld Magic, Zelda Real-Time Combat.
extends Node2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")



enum ClassTier { APPRENTICE, PYROMANCER, SPELLBLADE }
enum SpiritType { FLAME, FROST }

# Character State
var current_class: ClassTier = ClassTier.APPRENTICE
var active_spirit: SpiritType = SpiritType.FLAME
var player_level: int = 1
var player_exp: int = 0
var max_exp: int = 50

var hp: int = 100
var max_hp: int = 100
var attack_power: int = 15

# Puzzle & Dummy State
var dummy_hp: int = 150
var torch_lit: bool = false
var water_frozen: bool = false

@onready var player: Sprite2D = $Player
@onready var player_body: ColorRect = $Player/Body
@onready var camera: Camera2D = $Camera2D

@onready var dummy: Sprite2D = $Dummy
@onready var dummy_label: Label = $Dummy/HPLabel

@onready var torch: Sprite2D = $PuzzleTorch
@onready var torch_label: Label = $PuzzleTorch/Label

@onready var water_tile: ColorRect = $PuzzleWater
@onready var water_label: Label = $PuzzleWater/Label

@onready var hud_class_label: Label = $CanvasLayer/ClassLabel
@onready var hud_spirit_label: Label = $CanvasLayer/SpiritLabel
@onready var hud_instructions: Label = $CanvasLayer/InstructionsLabel
@onready var torch_light: PointLight2D = $PuzzleTorch/PointLight2D


func _ready() -> void:
	_update_character_stats()
	_update_ui()


func _physics_process(delta: float) -> void:
	var move_vec := Vector2.ZERO
	move_vec.x = Input.get_axis("move_left", "move_right")
	if InputMap.has_action("move_up") and InputMap.has_action("move_down"):
		move_vec.y = Input.get_axis("move_up", "move_down")
	else:
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			move_vec.y -= 1.0
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			move_vec.y += 1.0

	if move_vec.length() > 0:
		move_vec = move_vec.normalized()
		player.position += move_vec * 130.0 * delta
		player.position.x = clamp(player.position.x, 20, 460)
		player.position.y = clamp(player.position.y, 40, 250)

		# Allow crossing frozen water tile if frozen
		if not water_frozen and water_tile.get_global_rect().has_point(player.position):
			player.position -= move_vec * 130.0 * delta # Block movement into liquid water


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_menu.tscn")
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_J, KEY_SPACE:
				_sword_slash()
			KEY_K, KEY_SHIFT:
				_cast_spirit_magic()
			KEY_E:
				_swap_spirit_gem()
			KEY_P:
				_promote_class()


func _sword_slash() -> void:
	GameState.play_sfx("stomp")
	JuiceEffects.squash_and_stretch(player, Vector2(1.3, 0.7), 0.12)

	if player.position.distance_to(dummy.position) < 40.0:
		dummy_hp -= attack_power
		player_exp += 15
		if dummy_hp <= 0:
			dummy_hp = 150

		# Check level up / promotion eligibility
		if player_exp >= max_exp and current_class == ClassTier.APPRENTICE:
			_promote_class()

		dummy_label.text = "Gargoyle HP: %d" % dummy_hp
		JuiceEffects.freeze_frame(get_tree(), 0.06, 0.05)
		JuiceEffects.shake_camera(camera, 6.0, 0.15)
		JuiceEffects.flash_sprite(dummy, Color(3.0, 0.8, 0.4, 1.0), 0.1)

	_update_ui()


func _cast_spirit_magic() -> void:
	GameState.play_sfx("powerup")
	JuiceEffects.squash_and_stretch(player, Vector2(0.8, 1.4), 0.15)

	if active_spirit == SpiritType.FLAME:
		if player.position.distance_to(torch.position) < 50.0:
			torch_lit = !torch_lit
			torch.modulate = Color(3.0, 1.8, 0.5, 1.0) if torch_lit else Color(0.4, 0.4, 0.4, 1.0)
			torch_light.enabled = torch_lit
			torch_label.text = "Sun Torch: LIT!" if torch_lit else "Sun Torch: Unlit"
			JuiceEffects.flash_sprite(torch, Color(4.0, 2.5, 1.0, 1.0), 0.2)
			JuiceEffects.shake_camera(camera, 4.0, 0.1)
	elif active_spirit == SpiritType.FROST:
		if player.position.distance_to(water_tile.position + Vector2(25, 15)) < 60.0:
			water_frozen = !water_frozen
			water_tile.color = Color(0.6, 0.9, 1.0, 0.9) if water_frozen else Color(0.1, 0.3, 0.7, 0.7)
			water_label.text = "Ice Bridge (Passable)" if water_frozen else "Water (Blocked)"
			JuiceEffects.flash_sprite(water_tile, Color(1.0, 3.0, 3.0, 1.0), 0.2)
			JuiceEffects.shake_camera(camera, 4.0, 0.1)

	_update_ui()


func _swap_spirit_gem() -> void:
	active_spirit = SpiritType.FROST if active_spirit == SpiritType.FLAME else SpiritType.FLAME
	GameState.play_sfx("coin")
	_update_character_stats()
	_update_ui()


func _promote_class() -> void:
	if current_class == ClassTier.APPRENTICE:
		current_class = ClassTier.PYROMANCER if active_spirit == SpiritType.FLAME else ClassTier.SPELLBLADE
		GameState.play_sfx("win")
		JuiceEffects.freeze_frame(get_tree(), 0.1, 0.05)
		JuiceEffects.shake_camera(camera, 10.0, 0.3)
		JuiceEffects.flash_sprite(player, Color(4.0, 4.0, 4.0, 1.0), 0.3)
	elif current_class == ClassTier.PYROMANCER:
		current_class = ClassTier.SPELLBLADE
	else:
		current_class = ClassTier.PYROMANCER

	_update_character_stats()
	_update_ui()


func _update_character_stats() -> void:
	match current_class:
		ClassTier.APPRENTICE:
			attack_power = 15 + (5 if active_spirit == SpiritType.FLAME else 0)
			player_body.color = Color(0.3, 0.7, 0.4, 1) # Green tunic
		ClassTier.PYROMANCER:
			attack_power = 35 + (10 if active_spirit == SpiritType.FLAME else 0)
			player_body.color = Color(0.9, 0.3, 0.2, 1) # Red pyromancer robes
		ClassTier.SPELLBLADE:
			attack_power = 28 + (8 if active_spirit == SpiritType.FROST else 0)
			player_body.color = Color(0.2, 0.6, 0.9, 1) # Blue spellblade armor


func _update_ui() -> void:
	var class_name_str := "Apprentice (Rank 1)"
	if current_class == ClassTier.PYROMANCER:
		class_name_str = "PROMOTED: Pyromancer (Rank 2)"
	elif current_class == ClassTier.SPELLBLADE:
		class_name_str = "PROMOTED: Spellblade (Rank 2)"

	var spirit_name_str := "Flame Spirit (Ignite/Burn)" if active_spirit == SpiritType.FLAME else "Frost Spirit (Freeze Water)"

	hud_class_label.text = "CLASS: %s  |  ATK: %d  |  EXP: %d/%d" % [class_name_str, attack_power, player_exp, max_exp]
	hud_spirit_label.text = "EQUIPPED SPIRIT: [%s]" % spirit_name_str
	hud_instructions.text = "[WASD/Arrows] Move  |  [J/Space] Sword Attack  |  [K/Shift] Cast Magic\n[E] Swap Spirit Gem  |  [P] Rank-Up Class Promotion  |  [Esc] Toybox Menu"
