## VerticalSliceShrine — Gameplay Controller for "The Sunken Shrine of Sol"
## Manages real-time combat, enemy AI, Frost/Flame Spirit puzzles, and Class Promotion.
extends Node2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")




enum SpiritType { FLAME, FROST }
var active_spirit: SpiritType = SpiritType.FLAME

# Player Stats
var player_class: String = "Apprentice"
var player_level: int = 1
var player_hp: int = 100
var max_hp: int = 100
var attack_power: int = 15
var exp_points: int = 0

# World States
var torch_lit: bool = false
var water_frozen: bool = false
var chest_opened: bool = false
var door_unlocked: bool = false
var enemy_hp: int = 120

@onready var player: Sprite2D = $Player
@onready var player_sprite: Sprite2D = $Player
@onready var camera: Camera2D = $Camera2D

@onready var enemy: Sprite2D = $Enemy
@onready var enemy_sprite: Sprite2D = $Enemy
@onready var enemy_hp_label: Label = $Enemy/HPLabel

@onready var torch: Sprite2D = $Torch
@onready var torch_sprite: Sprite2D = $Torch
@onready var torch_light: PointLight2D = $Torch/PointLight2D
@onready var torch_label: Label = $Torch/Label

@onready var water_channel: ColorRect = $WaterChannel
@onready var water_label: Label = $WaterChannel/Label

@onready var chest: Sprite2D = $TreasureChest
@onready var chest_sprite: Sprite2D = $TreasureChest
@onready var chest_label: Label = $TreasureChest/Label

@onready var lore_tablet: Sprite2D = $LoreTablet
@onready var lore_label: Label = $CanvasLayer/LorePopup

@onready var hud_status: Label = $CanvasLayer/HUDStatus
@onready var hud_spirit: Label = $CanvasLayer/HUDSpirit
@onready var hud_guide: Label = $CanvasLayer/HUDGuide
@onready var promotion_ui: CanvasLayer = $CanvasLayer/ClassPromotionUI

@onready var prompt_tablet: Label = $LoreTablet/PromptLabel
@onready var prompt_water: Label = $WaterChannel/PromptLabel
@onready var prompt_torch: Label = $Torch/PromptLabel
@onready var prompt_chest: Label = $TreasureChest/PromptLabel

var tex_apprentice: Texture2D
var tex_pyro: Texture2D
var tex_blade: Texture2D
var tex_chest_c: Texture2D
var tex_chest_o: Texture2D
var tex_torch_u: Texture2D
var tex_torch_l: Texture2D


func _ready() -> void:
	_load_textures()
	if promotion_ui != null and promotion_ui.has_signal("promotion_selected"):
		promotion_ui.promotion_selected.connect(_on_promotion_selected)
	_update_ui()


func _load_textures() -> void:
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_apprentice.png"):
		tex_apprentice = load("res://games/tactics/assets/sprites/shrine/hero_apprentice.png")
		player_sprite.texture = tex_apprentice
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_pyromancer.png"):
		tex_pyro = load("res://games/tactics/assets/sprites/shrine/hero_pyromancer.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_spellblade.png"):
		tex_blade = load("res://games/tactics/assets/sprites/shrine/hero_spellblade.png")

	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/guardian.png"):
		enemy_sprite.texture = load("res://games/tactics/assets/sprites/shrine/guardian.png")

	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/chest_closed.png"):
		tex_chest_c = load("res://games/tactics/assets/sprites/shrine/chest_closed.png")
		chest_sprite.texture = tex_chest_c
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/chest_open.png"):
		tex_chest_o = load("res://games/tactics/assets/sprites/shrine/chest_open.png")

	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/torch_unlit.png"):
		tex_torch_u = load("res://games/tactics/assets/sprites/shrine/torch_unlit.png")
		torch_sprite.texture = tex_torch_u
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/torch_lit.png"):
		tex_torch_l = load("res://games/tactics/assets/sprites/shrine/torch_lit.png")

	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/stone_floor.png"):
		var tex_floor = load("res://games/tactics/assets/sprites/shrine/stone_floor.png")
		for node_name in ["BridgeFloor", "CombatChamber", "InnerSanctum"]:
			var node = get_node_or_null("ShrineStructures/" + node_name)
			if node is TextureRect:
				node.texture = tex_floor
				node.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _physics_process(delta: float) -> void:
	if promotion_ui != null and promotion_ui.get("is_active") == true:
		return

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

		# Water Channel Collision if not frozen
		if not water_frozen and water_channel.get_global_rect().has_point(player.position):
			player.position -= move_vec * 130.0 * delta # Block crossing liquid water

	# Simple Enemy AI patrol
	if enemy != null and enemy_hp > 0:
		var dist_to_player := enemy.position.distance_to(player.position)
		if dist_to_player < 100.0 and dist_to_player > 15.0:
			enemy.position = enemy.position.move_toward(player.position, 40.0 * delta)

	# Update Dynamic Proximity Prompts
	_update_proximity_prompts()


func _update_proximity_prompts() -> void:
	# Lore Tablet Prompt
	if prompt_tablet != null:
		prompt_tablet.visible = player.position.distance_to(lore_tablet.position) < 40.0

	# Water Channel Prompt
	if prompt_water != null:
		var near_water := player.position.distance_to(water_channel.position + Vector2(20, 30)) < 60.0
		prompt_water.visible = near_water
		if near_water:
			prompt_water.text = "[Shift/K] Cast Frost Magic" if active_spirit == SpiritType.FROST else "Equip Frost [E] to Freeze"

	# Sun Torch Prompt
	if prompt_torch != null:
		var near_torch := player.position.distance_to(torch.position) < 55.0
		prompt_torch.visible = near_torch
		if near_torch:
			prompt_torch.text = "[Shift/K] Cast Flame Magic" if active_spirit == SpiritType.FLAME else "Equip Flame [E] to Light"

	# Treasure Chest Prompt
	if prompt_chest != null:
		var near_chest := player.position.distance_to(chest.position) < 45.0
		prompt_chest.visible = near_chest
		if near_chest:
			if door_unlocked or torch_lit:
				prompt_chest.text = "[F] OPEN CHEST & PROMOTE CLASS!"
			else:
				prompt_chest.text = "[LOCKED] Light Sun Torch First!"


func _unhandled_input(event: InputEvent) -> void:
	if promotion_ui != null and promotion_ui.get("is_active") == true:
		return

	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn")
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_J, KEY_SPACE:
				_attack()
			KEY_K, KEY_SHIFT:
				_cast_magic()
			KEY_E:
				_swap_spirit()
			KEY_F:
				_interact()


func _attack() -> void:
	GameState.play_sfx("stomp")
	JuiceEffects.squash_and_stretch(player, Vector2(1.3, 0.7), 0.12)

	# Check collision with Enemy
	if enemy != null and player.position.distance_to(enemy.position) < 36.0:
		enemy_hp -= attack_power
		exp_points += 20
		if enemy_hp <= 0:
			enemy_hp = 120
			enemy_hp_label.text = "Shrine Guardian (Defeated!)"
		else:
			enemy_hp_label.text = "Shrine Guardian HP: %d" % enemy_hp

		JuiceEffects.freeze_frame(get_tree(), 0.06, 0.05)
		JuiceEffects.shake_camera(camera, 6.0, 0.15)
		JuiceEffects.flash_sprite(enemy, Color(3.0, 0.5, 0.2, 1.0), 0.12)

	_update_ui()


func _cast_magic() -> void:
	GameState.play_sfx("powerup")
	JuiceEffects.squash_and_stretch(player, Vector2(0.8, 1.4), 0.15)

	if active_spirit == SpiritType.FLAME:
		# Flame Spirit: Ignite Sun Torch
		if player.position.distance_to(torch.position) < 55.0:
			torch_lit = !torch_lit
			if tex_torch_l != null and torch_lit:
				torch_sprite.texture = tex_torch_l
			elif tex_torch_u != null:
				torch_sprite.texture = tex_torch_u

			torch_light.enabled = torch_lit
			torch_label.text = "Sun Torch: LIT!" if torch_lit else "Sun Torch: Unlit"
			door_unlocked = torch_lit
			JuiceEffects.flash_sprite(torch, Color(4.0, 2.5, 1.0, 1.0), 0.2)
			JuiceEffects.shake_camera(camera, 4.0, 0.1)
	elif active_spirit == SpiritType.FROST:
		# Frost Spirit: Freeze Water Channel into Ice Bridge
		if player.position.distance_to(water_channel.position + Vector2(20, 30)) < 60.0:
			water_frozen = !water_frozen
			water_channel.color = Color(0.6, 0.9, 1.0, 0.9) if water_frozen else Color(0.1, 0.3, 0.7, 0.7)
			water_label.text = "Ice Bridge (Passable)" if water_frozen else "Water Channel (Blocked)"
			JuiceEffects.flash_sprite(water_channel, Color(1.0, 3.0, 3.0, 1.0), 0.2)
			JuiceEffects.shake_camera(camera, 4.0, 0.1)

	_update_ui()


func _swap_spirit() -> void:
	active_spirit = SpiritType.FROST if active_spirit == SpiritType.FLAME else SpiritType.FLAME
	GameState.play_sfx("coin")
	_update_ui()


func _interact() -> void:
	# Read Lore Tablet
	if player.position.distance_to(lore_tablet.position) < 40.0:
		lore_label.text = "ANCIENT INSCRIPTION:\n'Equip Frost [E] to freeze the water channel. Equip Flame [E] and cast Magic [K] to light the Sun Torch and claim the Crest of Promotion!'"
		lore_label.visible = true
		get_tree().create_timer(5.0).timeout.connect(func(): if is_instance_valid(lore_label): lore_label.visible = false)
		return

	# Open Treasure Chest -> Trigger Class Promotion!
	if player.position.distance_to(chest.position) < 45.0:
		if door_unlocked or torch_lit:
			if not chest_opened:
				chest_opened = true
				if tex_chest_o != null:
					chest_sprite.texture = tex_chest_o
				chest_label.text = "Sunken Chest (OPENED!)"
				exp_points += 50
				player_level = 5
				JuiceEffects.flash_sprite(chest, Color(4.0, 4.0, 1.0, 1.0), 0.3)
				JuiceEffects.shake_camera(camera, 8.0, 0.2)

			# Trigger Fire Emblem Class Promotion Overlay!
			if promotion_ui != null:
				promotion_ui.call("open_promotion")
		else:
			lore_label.text = "The Sunken Chest is locked! Cast Flame Magic [Shift/K] near the Sun Torch first!"
			lore_label.visible = true
			get_tree().create_timer(4.0).timeout.connect(func(): if is_instance_valid(lore_label): lore_label.visible = false)


func _on_promotion_selected(new_class_name: String, atk_bonus: int, hp_bonus: int) -> void:
	player_class = new_class_name
	attack_power += atk_bonus
	max_hp += hp_bonus
	player_hp = max_hp

	if new_class_name == "Pyromancer" and tex_pyro != null:
		player_sprite.texture = tex_pyro
	elif new_class_name == "Spellblade" and tex_blade != null:
		player_sprite.texture = tex_blade

	_update_ui()


func _update_ui() -> void:
	var spirit_str := "Flame Spirit (Light Torch)" if active_spirit == SpiritType.FLAME else "Frost Spirit (Freeze Water)"
	hud_status.text = "SHRINE OF SOL  |  CLASS: %s (Lv %d)  |  HP: %d/%d  |  ATK: %d" % [player_class, player_level, player_hp, max_hp, attack_power]
	hud_spirit.text = "EQUIPPED SPIRIT: [%s]" % spirit_str
	hud_guide.text = "[WASD/Arrows] Move  |  [J/Space] Sword Slash  |  [K/Shift] Cast Magic\n[E] Swap Spirit  |  [F] Open Chest / Read Tablet  |  [Esc] Menu"

