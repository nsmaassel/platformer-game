## Concept B: Real-Time Grid Action (Mega Man Battle Network)
## Prototyping 3x3 Player Grid vs 3x3 Enemy Grid, tile dashing, deck chip execution, and dodging.
extends Node2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")



const CELL_SIZE: Vector2 = Vector2(40, 30)
const GRID_ORIGIN: Vector2 = Vector2(120, 110)

var player_grid: Vector2i = Vector2i(1, 1) # (0..2, 0..2)
var enemy_grid: Vector2i = Vector2i(4, 1)  # (3..5, 0..2)

var chips: Array[String] = ["Cyber Sword (100 Dmg)", "Wide Cannon (60 Dmg)", "Reflector Shield", "Thunder Bolt (80 Dmg)"]
var current_chip_idx: int = 0
var enemy_hp: int = 200

@onready var player_sprite: Sprite2D = $Player
@onready var enemy_sprite: Sprite2D = $Enemy
@onready var camera: Camera2D = $Camera2D
@onready var chip_label: Label = $CanvasLayer/ChipLabel
@onready var enemy_hp_label: Label = $Enemy/HPLabel
@onready var hud_label: Label = $CanvasLayer/HUDLabel


func _ready() -> void:
	_update_positions()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_menu.tscn")
		return

	if event is InputEventKey and event.pressed:
		var moved := false
		match event.keycode:
			KEY_W, KEY_UP:
				if player_grid.y > 0:
					player_grid.y -= 1
					moved = true
			KEY_S, KEY_DOWN:
				if player_grid.y < 2:
					player_grid.y += 1
					moved = true
			KEY_A, KEY_LEFT:
				if player_grid.x > 0:
					player_grid.x -= 1
					moved = true
			KEY_D, KEY_RIGHT:
				if player_grid.x < 2:
					player_grid.x += 1
					moved = true
			KEY_J, KEY_SPACE:
				_use_chip()
			KEY_K, KEY_SHIFT:
				_cycle_chip()

		if moved:
			GameState.play_sfx("jump")
			_update_positions()
			JuiceEffects.squash_and_stretch(player_sprite, Vector2(1.2, 0.8), 0.1)


func _use_chip() -> void:
	var chip_name := chips[current_chip_idx]
	GameState.play_sfx("stomp")

	# If player is in same row as enemy, hit!
	if player_grid.y == enemy_grid.y:
		enemy_hp -= 60
		if enemy_hp <= 0:
			enemy_hp = 200
		enemy_hp_label.text = "Mettaur HP: %d" % enemy_hp

		JuiceEffects.freeze_frame(get_tree(), 0.05, 0.05)
		JuiceEffects.shake_camera(camera, 6.0, 0.15)
		JuiceEffects.flash_sprite(enemy_sprite, Color(3.0, 1.0, 0.5, 1.0), 0.12)

	_cycle_chip()
	_update_hud()


func _cycle_chip() -> void:
	current_chip_idx = (current_chip_idx + 1) % chips.size()
	_update_hud()


func _update_positions() -> void:
	player_sprite.position = GRID_ORIGIN + Vector2(player_grid.x * CELL_SIZE.x, player_grid.y * CELL_SIZE.y)
	enemy_sprite.position = GRID_ORIGIN + Vector2(enemy_grid.x * CELL_SIZE.x, enemy_grid.y * CELL_SIZE.y)


func _update_hud() -> void:
	chip_label.text = "READY CHIP: [%s]" % chips[current_chip_idx]
	hud_label.text = "[CONCEPT B: Mega Man Battle Network]\n[WASD/Arrows] Grid Dash  |  [J/Space] Execute Chip  |  [K/Shift] Swap Chip  |  [Esc] Menu"
