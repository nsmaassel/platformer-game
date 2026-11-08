## Concept C: Tactical Grid Creature RPG (Fire Emblem x Pokémon)
## Prototyping turn-based grid movement, creature unit selection, attack range preview, and crit cut-in.
extends Node2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")



const TILE_SIZE: Vector2 = Vector2(32, 32)
const GRID_OFFSET: Vector2 = Vector2(60, 60)

var cursor_grid: Vector2i = Vector2i(2, 2)
var selected_unit_grid: Vector2i = Vector2i(2, 2)
var is_unit_selected: bool = false

var enemy_unit_grid: Vector2i = Vector2i(5, 2)
var enemy_hp: int = 120

@onready var cursor_sprite: Sprite2D = $Cursor
@onready var creature_sprite: Sprite2D = $CreatureUnit
@onready var enemy_sprite: Sprite2D = $EnemyUnit
@onready var camera: Camera2D = $Camera2D
@onready var enemy_hp_label: Label = $EnemyUnit/HPLabel
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
				if cursor_grid.y > 0:
					cursor_grid.y -= 1
					moved = true
			KEY_S, KEY_DOWN:
				if cursor_grid.y < 4:
					cursor_grid.y += 1
					moved = true
			KEY_A, KEY_LEFT:
				if cursor_grid.x > 0:
					cursor_grid.x -= 1
					moved = true
			KEY_D, KEY_RIGHT:
				if cursor_grid.x < 7:
					cursor_grid.x += 1
					moved = true
			KEY_J, KEY_SPACE:
				_interact_tile()
			KEY_K, KEY_SHIFT:
				_cancel_selection()

		if moved:
			GameState.play_sfx("coin")
			_update_positions()


func _interact_tile() -> void:
	if not is_unit_selected:
		# Select creature unit if cursor is over it
		if cursor_grid == selected_unit_grid:
			is_unit_selected = true
			GameState.play_sfx("powerup")
			JuiceEffects.squash_and_stretch(creature_sprite, Vector2(1.3, 0.7), 0.15)
	else:
		# Move unit to cursor or attack if adjacent to enemy
		if cursor_grid == enemy_unit_grid or cursor_grid.distance_to(enemy_unit_grid) == 1.0:
			_attack_enemy()
		else:
			selected_unit_grid = cursor_grid
			is_unit_selected = false
			GameState.play_sfx("jump")
			JuiceEffects.squash_and_stretch(creature_sprite, Vector2(0.8, 1.2), 0.15)

	_update_positions()
	_update_hud()


func _cancel_selection() -> void:
	is_unit_selected = false
	_update_hud()


func _attack_enemy() -> void:
	GameState.play_sfx("stomp")
	enemy_hp -= 40
	if enemy_hp <= 0:
		enemy_hp = 120
	enemy_hp_label.text = "Wild Vulpix HP: %d" % enemy_hp

	# Trigger Tactical Crit Hit-Stop & Screen Shake
	JuiceEffects.freeze_frame(get_tree(), 0.08, 0.04)
	JuiceEffects.shake_camera(camera, 8.0, 0.2)
	JuiceEffects.flash_sprite(enemy_sprite, Color(4.0, 0.5, 0.2, 1.0), 0.15)
	is_unit_selected = false


func _update_positions() -> void:
	cursor_sprite.position = GRID_OFFSET + Vector2(cursor_grid.x * TILE_SIZE.x, cursor_grid.y * TILE_SIZE.y)
	creature_sprite.position = GRID_OFFSET + Vector2(selected_unit_grid.x * TILE_SIZE.x, selected_unit_grid.y * TILE_SIZE.y)
	enemy_sprite.position = GRID_OFFSET + Vector2(enemy_unit_grid.x * TILE_SIZE.x, enemy_unit_grid.y * TILE_SIZE.y)


func _update_hud() -> void:
	var mode_text := "UNIT SELECTED — Choose Tile or Target" if is_unit_selected else "SELECT UNIT — Press [J/Space]"
	hud_label.text = "[CONCEPT C: Fire Emblem x Pokémon]\n[WASD/Arrows] Cursor  |  [J/Space] %s  |  [K/Shift] Cancel  |  [Esc] Menu" % mode_text
