# scripts/tactical_grid_prototype.gd
extends Node2D


const TacticalBoard = preload("res://games/tactics/scripts/tactics/tactical_board.gd")
const TacticalAbilities = preload("res://games/tactics/scripts/tactics/tactical_abilities.gd")
const TacticalAI = preload("res://games/tactics/scripts/tactics/tactical_ai.gd")
const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")
const Telemetry = preload("res://shared/scripts/telemetry.gd")

## Cell geometry comes from the board: tiles and highlights fill a cell minus a 1 px gap on each side.
const CELL_RECT := Vector2(TacticalBoard.GRID_SIZE - 2, TacticalBoard.GRID_SIZE - 2)
const CELL_HALF := Vector2(TacticalBoard.GRID_SIZE / 2.0 - 1.0, TacticalBoard.GRID_SIZE / 2.0 - 1.0)
## Sun & Steel art (tools/art): 32x32 units whose feet sit on rows 28-30; this offset puts them on the cell's bottom edge.
const SUN_STEEL := "res://games/tactics/assets/sprites/sun_steel/"
const UNIT_ART_OFFSET := Vector2(0, -3)
const MAX_ART_FRAMES := 16
## HP bars sit just above a 32 px unit's head.
const HP_BG_OFFSET := Vector2(9, 23)
const HP_BAR_OFFSET := Vector2(8, 22)
## Unit art drawn facing left (flip logic assumes right-facing art).
const ART_FACES_LEFT := ["unit_golem"]

var board: TacticalBoard
var current_turn: String = "PLAYER"
var selected_unit: Dictionary = {}
var active_units: Array = []
var grid_highlights: Dictionary = {}
var ability_mode: String = "NONE"

@onready var tile_container: Node2D = $TileContainer
@onready var highlight_container: Node2D = $HighlightContainer
@onready var unit_container: Node2D = $UnitContainer
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var hud_turn_label: Label = $CanvasLayer/HUDTurnLabel
@onready var hud_unit_info: Label = $CanvasLayer/HUDUnitInfo
@onready var btn_end_turn: Button = $CanvasLayer/BtnEndTurn
@onready var btn_ability: Button = $CanvasLayer/BtnAbility
@onready var btn_main_menu: Button = $CanvasLayer/BtnMainMenu
@onready var victory_label: Label = $CanvasLayer/VictoryLabel

var hover_container: Node2D
var camera: Camera2D

var tex_hero_apprentice: Texture2D
var tex_hero_pyro: Texture2D
var tex_hero_blade: Texture2D
var tex_hero_ranger: Texture2D
var tex_hero_cleric: Texture2D
var tex_golem: Texture2D
var tex_cover_rock: Texture2D
var tex_floor: Texture2D

func _ready() -> void:
	board = TacticalBoard.new()
	
	hover_container = Node2D.new()
	add_child(hover_container)
	move_child(hover_container, unit_container.get_index())
	
	camera = Camera2D.new()
	camera.position = Vector2(240, 135)
	add_child(camera)
	
	_load_textures()
	_create_grid_tiles()
	_spawn_initial_units()
	
	if victory_label: victory_label.visible = false
	if btn_end_turn: btn_end_turn.pressed.connect(_on_end_turn_pressed)
	if btn_ability: btn_ability.pressed.connect(_on_ability_pressed)
	if btn_main_menu: btn_main_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn"))
	
	_update_hud()
	_log_telemetry("TACTICS_START", {"turn": current_turn, "units": active_units.size()})

func _process(delta: float) -> void:
	var time = Time.get_ticks_msec() / 1000.0
	for u in active_units:
		if u.get("sprite") and not u.get("animated", false) and not u.get("is_moving", false) and not u.get("has_acted", false):
			var base_pos = board.grid_to_world(u["pos"])
			u["sprite"].position.y = base_pos.y + sin(time * 5.0 + u["pos"].x) * 2.0

func _load_textures() -> void:
	tex_hero_apprentice = _load_texture_direct("res://games/tactics/assets/sprites/shrine/hero_apprentice.png")
	tex_hero_pyro = _load_texture_direct("res://games/tactics/assets/sprites/shrine/hero_pyromancer.png")
	tex_hero_blade = _load_texture_direct("res://games/tactics/assets/sprites/shrine/hero_spellblade.png")
	tex_hero_ranger = _load_texture_direct("res://games/tactics/assets/sprites/shrine/hero_ranger.png")
	tex_hero_cleric = _load_texture_direct("res://games/tactics/assets/sprites/shrine/hero_cleric.png")
	tex_golem = _load_texture_direct("res://games/tactics/assets/sprites/shrine/guardian.png")
	tex_cover_rock = _load_texture_direct(SUN_STEEL + "prop_cover_rock.0.png")
	tex_floor = _load_texture_direct(SUN_STEEL + "tile_floor.0.png")

func _load_texture_direct(res_path: String) -> Texture2D:
	var global_p = ProjectSettings.globalize_path(res_path)
	if FileAccess.file_exists(global_p):
		var img = Image.load_from_file(global_p)
		if img and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(res_path): return load(res_path) as Texture2D
	return null

func _create_grid_tiles() -> void:
	var lava_frames := _make_frames("tile_lava", 4.0)
	for y in range(board.BOARD_HEIGHT):
		for x in range(board.BOARD_WIDTH):
			var pos = Vector2i(x, y)
			var center = board.grid_to_world(pos)
			var ttype = board.terrain_map.get(pos, "")
			if ttype == "LAVA" and lava_frames:
				var lava := AnimatedSprite2D.new()
				lava.sprite_frames = lava_frames
				lava.position = center
				lava.play("default")
				tile_container.add_child(lava)
			elif tex_floor and ttype != "LAVA":
				_add_tile_sprite(tex_floor, center)
				if ttype == "COVER" and tex_cover_rock:
					_add_tile_sprite(tex_cover_rock, center)
			else:
				# Fallback when the art is missing: the original coloured cells.
				var tile = ColorRect.new()
				tile.size = CELL_RECT
				tile.position = center - CELL_HALF
				if ttype == "COVER":
					tile.color = Color(0.3, 0.35, 0.45, 0.9)
				elif ttype == "LAVA":
					tile.color = Color(0.8, 0.2, 0.1, 0.9)
				else:
					tile.color = Color(0.12, 0.15, 0.22, 0.8) if (x + y) % 2 == 0 else Color(0.16, 0.20, 0.28, 0.8)
				tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
				tile_container.add_child(tile)

func _add_tile_sprite(tex: Texture2D, center: Vector2) -> void:
	var spr = Sprite2D.new()
	spr.texture = tex
	spr.position = center
	tile_container.add_child(spr)

## Builds a looping "default" animation from sun_steel/<art>.0.png, .1.png, ... (as many frames as tools/art
## produced), or returns null when there is no frame 0. Cached, so units of one type share a SpriteFrames.
var _frames_cache: Dictionary = {}
func _make_frames(art: String, fps: float) -> SpriteFrames:
	var key := "%s@%s" % [art, fps]
	if _frames_cache.has(key):
		return _frames_cache[key]
	var frames: SpriteFrames = null
	for i in range(MAX_ART_FRAMES):
		var tex = _load_texture_direct(SUN_STEEL + "%s.%d.png" % [art, i])
		if tex == null:
			break
		if frames == null:
			frames = SpriteFrames.new()
			frames.set_animation_speed("default", fps)
			frames.set_animation_loop("default", true)
		frames.add_frame("default", tex)
	_frames_cache[key] = frames
	return frames

func _spawn_initial_units() -> void:
	_create_unit("p1", "Sun Knight", "Knight", "PLAYER", Vector2i(2, 2), 45, 14, 3, 1, tex_hero_apprentice, "unit_sun_knight")
	_create_unit("p2", "Pyromancer", "Mage", "PLAYER", Vector2i(2, 7), 30, 18, 2, 3, tex_hero_pyro, "unit_pyromancer")
	_create_unit("p3", "Frost Blade", "Spellblade", "PLAYER", Vector2i(1, 4), 35, 15, 4, 1, tex_hero_blade, "unit_frost_blade")
	_create_unit("p4", "Sun Ranger", "Ranger", "PLAYER", Vector2i(1, 1), 32, 16, 3, 4, tex_hero_ranger, "unit_ranger")
	_create_unit("p5", "Sun Cleric", "Cleric", "PLAYER", Vector2i(1, 8), 38, 8, 3, 2, tex_hero_cleric, "unit_cleric")

	_create_unit("e1", "Basalt Golem", "Golem", "ENEMY", Vector2i(9, 3), 60, 16, 2, 1, tex_golem, "unit_golem")
	_create_unit("e2", "Cinder Golem", "Golem", "ENEMY", Vector2i(9, 6), 60, 16, 2, 1, tex_golem, "unit_golem")
	_create_unit("e3", "Ash Golem", "Golem", "ENEMY", Vector2i(10, 4), 50, 14, 3, 1, tex_golem, "unit_golem")

func _create_unit(id: String, uname: String, uclass: String, team: String, grid_pos: Vector2i, hp: int, atk: int, move_r: int, atk_r: int, tex: Texture2D, art: String = "") -> void:
	# sun_steel art: 32x32 idle animation at 1:1, feet on the cell's bottom edge. Until a hero's art exists,
	# its August placeholder texture is shown instead, scaled to fit the cell.
	var frames: SpriteFrames = _make_frames(art, 6.0) if art != "" else null
	var sprite: Node2D
	if frames:
		var anim := AnimatedSprite2D.new()
		anim.sprite_frames = frames
		anim.offset = UNIT_ART_OFFSET
		anim.play("default")
		anim.frame = (grid_pos.x + grid_pos.y) % frames.get_frame_count("default")  # desynchronise idle loops
		sprite = anim
	else:
		var placeholder := Sprite2D.new()
		placeholder.texture = tex
		if tex:
			var max_dim = float(max(tex.get_width(), tex.get_height()))
			if max_dim > 24.0:
				var sc = 22.0 / max_dim
				placeholder.scale = Vector2(sc, sc)
		sprite = placeholder
	sprite.position = board.grid_to_world(grid_pos)
	unit_container.add_child(sprite)

	var hp_bar = ColorRect.new()
	hp_bar.size = Vector2(16, 2)
	hp_bar.position = board.grid_to_world(grid_pos) - HP_BAR_OFFSET
	hp_bar.color = Color(0.2, 0.9, 0.3)
	hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_container.add_child(hp_bar)

	# The backing frame is a child of the bar, so it moves and is freed with it (it used to stay at the spawn cell).
	var hp_bg = ColorRect.new()
	hp_bg.size = Vector2(18, 4)
	hp_bg.position = HP_BAR_OFFSET - HP_BG_OFFSET
	hp_bg.color = Color(0.05, 0.05, 0.1, 0.8)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_bg.show_behind_parent = true
	hp_bar.add_child(hp_bg)

	active_units.append({
		"id": id, "name": uname, "class": uclass, "team": team, "pos": grid_pos,
		"hp": hp, "max_hp": hp, "atk": atk, "move_range": move_r, "atk_range": atk_r,
		"has_acted": false, "is_moving": false, "sprite": sprite, "hp_bar": hp_bar,
		"animated": frames != null, "art_faces_left": frames != null and ART_FACES_LEFT.has(art)
	})
	# Player units face right, enemy units face left
	_face(active_units[-1], -1 if team == "ENEMY" else 1)

## Points a unit left (dir_x < 0) or right (dir_x > 0), flipping the other way for art drawn facing left.
func _face(unit: Dictionary, dir_x: int) -> void:
	var spr = unit.get("sprite")
	if spr == null or dir_x == 0:
		return
	spr.flip_h = (dir_x < 0) != unit.get("art_faces_left", false)

var last_hovered_grid: Vector2i = Vector2i(-1, -1)
func _input(event: InputEvent) -> void:
	if current_turn != "PLAYER": return
	# The HUD panel sits right of the board; ignore points off the board so HUD clicks are not board clicks too.
	if not board.is_on_board(get_global_mouse_position()): return
	if event is InputEventMouseMotion:
		var hovered_grid = board.world_to_grid(get_global_mouse_position())
		if hovered_grid != last_hovered_grid:
			last_hovered_grid = hovered_grid
			_handle_grid_hover(hovered_grid)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_grid = board.world_to_grid(get_global_mouse_position())
		_handle_grid_click(clicked_grid)

func _handle_grid_hover(grid_pos: Vector2i) -> void:
	for child in hover_container.get_children(): child.queue_free()
	if not selected_unit.is_empty():
		if grid_highlights.has(grid_pos) and grid_highlights[grid_pos] == Color(0.2, 0.6, 1.0, 0.5):
			var path = board.astar_grid.get_id_path(selected_unit["pos"], grid_pos)
			for i in range(1, path.size()):
				var p_rect = ColorRect.new()
				p_rect.size = Vector2(6, 6)
				p_rect.position = board.grid_to_world(path[i]) - Vector2(3, 3)
				p_rect.color = Color(1.0, 1.0, 1.0, 0.6)
				p_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hover_container.add_child(p_rect)
	else:
		var hovered = _get_unit_at(grid_pos)
		if not hovered.is_empty() and hovered["team"] == "ENEMY":
			board.update_astar_units(active_units, "ENEMY")
			var u_pos = hovered["pos"]
			var m_r = hovered["move_range"]
			for y in range(board.BOARD_HEIGHT):
				for x in range(board.BOARD_WIDTH):
					var target = Vector2i(x, y)
					if target != u_pos:
						var path = board.astar_grid.get_id_path(u_pos, target)
						if path.size() > 0 and path.size() - 1 <= m_r:
							var r = ColorRect.new()
							r.size = CELL_RECT
							r.position = board.grid_to_world(target) - CELL_HALF
							r.color = Color(0.5, 0.1, 0.1, 0.2)
							hover_container.add_child(r)

func _handle_grid_click(grid_pos: Vector2i) -> void:
	var clicked_unit = _get_unit_at(grid_pos)
	if ability_mode != "NONE":
		_execute_active_ability(grid_pos)
		return
	if selected_unit.is_empty():
		if not clicked_unit.is_empty() and clicked_unit["team"] == "PLAYER" and not clicked_unit["has_acted"]:
			_select_unit(clicked_unit)
	else:
		if grid_highlights.has(grid_pos) and grid_highlights[grid_pos] == Color(0.2, 0.6, 1.0, 0.5):
			_move_unit(selected_unit, grid_pos)
		elif not clicked_unit.is_empty() and clicked_unit["team"] == "ENEMY" and grid_highlights.has(grid_pos) and grid_highlights[grid_pos] == Color(1.0, 0.2, 0.2, 0.5):
			_attack_unit(selected_unit, clicked_unit)
		elif not clicked_unit.is_empty() and clicked_unit["team"] == "PLAYER" and selected_unit["class"] == "Cleric" and grid_highlights.has(grid_pos) and grid_highlights[grid_pos] == Color(0.3, 1.0, 0.4, 0.5):
			_heal_unit(selected_unit, clicked_unit)
		else:
			_deselect_unit()

func _select_unit(unit: Dictionary) -> void:
	selected_unit = unit
	ability_mode = "NONE"
	_clear_highlights()
	_calculate_highlights(unit)
	_update_hud()

func _deselect_unit() -> void:
	selected_unit = {}
	ability_mode = "NONE"
	_clear_highlights()
	_update_hud()
	_check_auto_end_phase()

func _move_unit(unit: Dictionary, target_grid: Vector2i) -> void:
	var old_pos = unit["pos"]
	unit["pos"] = target_grid
	var sprite = unit["sprite"]
	var hp_bar = unit["hp_bar"]
	var world_p = board.grid_to_world(target_grid)
	if sprite:
		unit["is_moving"] = true
		_face(unit, signi(target_grid.x - old_pos.x))

		var tween = create_tween()
		tween.tween_property(sprite, "position", world_p, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if hp_bar: tween.parallel().tween_property(hp_bar, "position", world_p - HP_BAR_OFFSET, 0.2)
		tween.tween_callback(func(): unit["is_moving"] = false)

	if board.terrain_map.get(target_grid) == "LAVA":
		unit["hp"] = max(0, unit["hp"] - 10)
		JuiceEffects.flash_sprite(sprite, Color(1, 0.3, 0.1), 0.3)
		if unit["hp"] <= 0: _destroy_unit(unit)

	_update_unit_hp_bar(unit)
	_clear_highlights()
	_calculate_highlights(unit)
	_auto_end_unit_if_no_targets(unit)
	_check_auto_end_phase()

func _attack_unit(attacker: Dictionary, defender: Dictionary) -> void:
	attacker["has_acted"] = true
	if attacker.get("sprite") and defender.get("pos"):
		_face(attacker, signi(defender["pos"].x - attacker["pos"].x))

	var dmg = attacker["atk"]
	if board.terrain_map.get(defender["pos"]) == "COVER": dmg = int(round(dmg * 0.7))
	defender["hp"] = max(0, defender["hp"] - dmg)
	_spawn_floating_text(str(-dmg), board.grid_to_world(defender["pos"]), Color(1, 0.2, 0.2))
	_update_unit_hp_bar(defender)
	JuiceEffects.flash_sprite(defender["sprite"], Color(1, 0.2, 0.2), 0.2)
	JuiceEffects.squash_and_stretch(attacker["sprite"], Vector2(1.2, 0.8), 0.15)
	_play_sfx("hit")
	if defender["hp"] <= 0: _destroy_unit(defender)
	_deselect_unit()
	_check_win_lose_conditions()

func _heal_unit(healer: Dictionary, target: Dictionary) -> void:
	healer["has_acted"] = true
	target["hp"] = min(target["max_hp"], target["hp"] + 15)
	_spawn_floating_text("+15", board.grid_to_world(target["pos"]), Color(0.3, 1.0, 0.4))
	_update_unit_hp_bar(target)
	JuiceEffects.flash_sprite(target["sprite"], Color(0.3, 1.0, 0.4), 0.3)
	_play_sfx("powerup")
	_deselect_unit()

func _on_ability_pressed() -> void:
	if selected_unit.is_empty() or selected_unit["has_acted"]: return
	var uclass = selected_unit["class"]
	if uclass == "Mage": ability_mode = "FIREBALL"
	elif uclass == "Knight": ability_mode = "SHIELD_BASH"
	elif uclass == "Spellblade": ability_mode = "ICE_DASH"
	elif uclass == "Ranger": ability_mode = "PIERCING_SHOT"
	elif uclass == "Cleric": ability_mode = "HEALING_LIGHT"
	_clear_highlights()
	grid_highlights = TacticalAbilities.get_ability_highlights(board, ability_mode, selected_unit["pos"])
	_render_highlights()

func _execute_active_ability(target_grid: Vector2i) -> void:
	if not grid_highlights.has(target_grid):
		_deselect_unit()
		return
	if ability_mode == "FIREBALL": _cast_fireball(target_grid)
	elif ability_mode == "SHIELD_BASH": _execute_shield_bash(target_grid)
	elif ability_mode == "ICE_DASH": _execute_ice_dash(target_grid)
	elif ability_mode == "PIERCING_SHOT": _execute_piercing_shot(target_grid)
	elif ability_mode == "HEALING_LIGHT": _execute_healing_light(target_grid)

func _cast_fireball(center_grid: Vector2i) -> void:
	selected_unit["has_acted"] = true
	for y in range(-1, 2):
		for x in range(-1, 2):
			var pos = center_grid + Vector2i(x, y)
			var target_unit = _get_unit_at(pos)
			if not target_unit.is_empty():
				target_unit["hp"] = max(0, target_unit["hp"] - 14)
				_spawn_floating_text("-14", board.grid_to_world(target_unit["pos"]), Color(1.0, 0.4, 0.1))
				if camera: JuiceEffects.shake_camera(camera, 5.0, 0.25)
				_update_unit_hp_bar(target_unit)
				JuiceEffects.flash_sprite(target_unit["sprite"], Color(1.0, 0.4, 0.1), 0.3)
				if target_unit["hp"] <= 0: _destroy_unit(target_unit)
	_play_sfx("hit")
	_deselect_unit()
	_check_win_lose_conditions()

func _execute_shield_bash(target_grid: Vector2i) -> void:
	selected_unit["has_acted"] = true
	var defender = _get_unit_at(target_grid)
	if not defender.is_empty():
		defender["hp"] = max(0, defender["hp"] - 12)
		_spawn_floating_text("-12", board.grid_to_world(defender["pos"]), Color(0.8, 0.2, 0.9))
		if camera: JuiceEffects.shake_camera(camera, 4.0, 0.2)
		_update_unit_hp_bar(defender)
		var push_dir = (target_grid - selected_unit["pos"])
		var pushed_pos = target_grid + push_dir
		if board.is_valid_grid(pushed_pos) and _get_unit_at(pushed_pos).is_empty():
			defender["pos"] = pushed_pos
			if defender["sprite"]: defender["sprite"].position = board.grid_to_world(pushed_pos)
			if defender["hp_bar"]: defender["hp_bar"].position = board.grid_to_world(pushed_pos) - HP_BAR_OFFSET
		JuiceEffects.flash_sprite(defender["sprite"], Color(0.8, 0.2, 0.9), 0.3)
		if defender["hp"] <= 0: _destroy_unit(defender)
	_play_sfx("hit")
	_deselect_unit()
	_check_win_lose_conditions()

func _execute_ice_dash(target_grid: Vector2i) -> void:
	selected_unit["has_acted"] = true
	var start_pos = selected_unit["pos"]
	selected_unit["pos"] = target_grid
	if selected_unit["sprite"]: selected_unit["sprite"].position = board.grid_to_world(target_grid)
	if selected_unit["hp_bar"]: selected_unit["hp_bar"].position = board.grid_to_world(target_grid) - HP_BAR_OFFSET
	
	var path_dir = (target_grid - start_pos)
	var steps = max(abs(path_dir.x), abs(path_dir.y))
	if steps > 0:
		var step_vec = path_dir / steps
		for s in range(1, steps + 1):
			var p = start_pos + step_vec * s
			var defender = _get_unit_at(p)
			if not defender.is_empty() and defender["id"] != selected_unit["id"]:
				defender["hp"] = max(0, defender["hp"] - 12)
				_spawn_floating_text("-12", board.grid_to_world(defender["pos"]), Color(0.8, 0.2, 0.9))
				if camera: JuiceEffects.shake_camera(camera, 4.0, 0.2)
				_update_unit_hp_bar(defender)
				JuiceEffects.flash_sprite(defender["sprite"], Color(0.2, 0.9, 1.0), 0.3)
				if defender["hp"] <= 0: _destroy_unit(defender)
	_play_sfx("powerup")
	_deselect_unit()
	_check_win_lose_conditions()

func _execute_piercing_shot(target_grid: Vector2i) -> void:
	selected_unit["has_acted"] = true
	var start_pos = selected_unit["pos"]
	var path_dir = (target_grid - start_pos).sign()
	for step in range(1, 7):
		var p = start_pos + path_dir * step
		if not board.is_valid_grid(p): break
		var defender = _get_unit_at(p)
		if not defender.is_empty() and defender["team"] != selected_unit["team"]:
			defender["hp"] = max(0, defender["hp"] - 20)
			_spawn_floating_text("-20", board.grid_to_world(defender["pos"]), Color(1.0, 0.8, 0.1))
			if camera: JuiceEffects.shake_camera(camera, 6.0, 0.3)
			_update_unit_hp_bar(defender)
			JuiceEffects.flash_sprite(defender["sprite"], Color(1.0, 0.8, 0.1), 0.3)
			if defender["hp"] <= 0: _destroy_unit(defender)
	_play_sfx("hit")
	_deselect_unit()
	_check_win_lose_conditions()

func _execute_healing_light(center_grid: Vector2i) -> void:
	selected_unit["has_acted"] = true
	for y in range(-1, 2):
		for x in range(-1, 2):
			var p = center_grid + Vector2i(x, y)
			var target_unit = _get_unit_at(p)
			if not target_unit.is_empty() and target_unit["team"] == selected_unit["team"]:
				target_unit["hp"] = min(target_unit["max_hp"], target_unit["hp"] + 25)
				_spawn_floating_text("+25", board.grid_to_world(target_unit["pos"]), Color(0.3, 1.0, 0.4))
				_update_unit_hp_bar(target_unit)
				JuiceEffects.flash_sprite(target_unit["sprite"], Color(0.2, 1.0, 0.5), 0.3)
	_play_sfx("powerup")
	_deselect_unit()

func _calculate_highlights(unit: Dictionary) -> void:
	var u_pos = unit["pos"]
	var move_r = unit["move_range"]
	var atk_r = unit["atk_range"]

	board.update_astar_units(active_units, unit["team"])
	for y in range(board.BOARD_HEIGHT):
		for x in range(board.BOARD_WIDTH):
			var target = Vector2i(x, y)
			if target != u_pos:
				var path = board.astar_grid.get_id_path(u_pos, target)
				if path.size() > 0 and path.size() - 1 <= move_r:
					if _get_unit_at(target).is_empty():
						grid_highlights[target] = Color(0.2, 0.6, 1.0, 0.5)

	for y in range(-atk_r, atk_r + 1):
		for x in range(-atk_r, atk_r + 1):
			var dist = abs(x) + abs(y)
			if dist <= atk_r and dist > 0:
				var target = u_pos + Vector2i(x, y)
				if board.is_valid_grid(target) and board.has_line_of_sight(u_pos, target):
					var target_unit = _get_unit_at(target)
					if not target_unit.is_empty():
						if target_unit["team"] != unit["team"]:
							grid_highlights[target] = Color(1.0, 0.2, 0.2, 0.5)
						elif unit["class"] == "Cleric" and target_unit["team"] == "PLAYER":
							grid_highlights[target] = Color(0.3, 1.0, 0.4, 0.5)
	_render_highlights()

func _render_highlights() -> void:
	for child in highlight_container.get_children(): child.queue_free()
	for pos in grid_highlights:
		var rect = ColorRect.new()
		rect.size = CELL_RECT
		rect.position = board.grid_to_world(pos) - CELL_HALF
		rect.color = grid_highlights[pos]
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		highlight_container.add_child(rect)

func _clear_highlights() -> void:
	grid_highlights.clear()
	for child in highlight_container.get_children(): child.queue_free()

func _update_unit_hp_bar(unit: Dictionary) -> void:
	var hp_bar = unit.get("hp_bar") as ColorRect
	if hp_bar:
		var pct = float(unit["hp"]) / float(unit["max_hp"])
		hp_bar.size.x = max(1.0, 16.0 * pct)
		hp_bar.color = Color(0.2, 0.9, 0.3) if pct > 0.4 else Color(0.9, 0.2, 0.2)

func _destroy_unit(unit: Dictionary) -> void:
	if unit.get("sprite"): unit["sprite"].queue_free()
	if unit.get("hp_bar"): unit["hp_bar"].queue_free()
	active_units.erase(unit)

func _on_end_turn_pressed() -> void:
	if current_turn == "PLAYER": _start_enemy_turn()

func _start_enemy_turn() -> void:
	current_turn = "ENEMY"
	_deselect_unit()
	_update_hud()
	var enemy_tween = create_tween()
	if enemy_tween:
		enemy_tween.tween_interval(0.15)
		enemy_tween.tween_callback(func():
			_run_enemy_ai()
			_start_player_turn()
		)

func _run_enemy_ai() -> void:
	for unit in active_units:
		if unit["team"] == "ENEMY" and unit["hp"] > 0:
			var move_result = TacticalAI.calculate_enemy_move(unit, active_units, board)
			if move_result["move_pos"] != unit["pos"]:
				unit["pos"] = move_result["move_pos"]
				if unit["sprite"]: unit["sprite"].position = board.grid_to_world(unit["pos"])
				if unit["hp_bar"]: unit["hp_bar"].position = board.grid_to_world(unit["pos"]) - HP_BAR_OFFSET
			if not move_result["attack_target"].is_empty():
				_attack_unit(unit, move_result["attack_target"])

func _start_player_turn() -> void:
	current_turn = "PLAYER"
	for unit in active_units:
		if unit["team"] == "PLAYER": unit["has_acted"] = false
	_update_hud()

func _check_win_lose_conditions() -> void:
	var player_count = 0
	var enemy_count = 0
	for unit in active_units:
		if unit["team"] == "PLAYER": player_count += 1
		if unit["team"] == "ENEMY": enemy_count += 1

	if enemy_count == 0 and victory_label:
		victory_label.text = "🏆 TACTICAL VICTORY! ALL ENEMIES ELIMINATED 🏆"
		victory_label.visible = true
	elif player_count == 0 and victory_label:
		victory_label.text = "💀 DEFEAT! PARTY ELIMINATED 💀"
		victory_label.visible = true

func _update_hud() -> void:
	if hud_turn_label:
		hud_turn_label.text = "CURRENT TURN: %s" % current_turn
		hud_turn_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0) if current_turn == "PLAYER" else Color(1.0, 0.3, 0.3))

	if btn_ability:
		btn_ability.visible = not selected_unit.is_empty() and not selected_unit["has_acted"]
		if not selected_unit.is_empty():
			var uclass = selected_unit["class"]
			if uclass == "Mage": btn_ability.text = "🔥 FIREBALL"
			elif uclass == "Knight": btn_ability.text = "🛡️ SHIELD BASH"
			elif uclass == "Spellblade": btn_ability.text = "❄️ ICE DASH"
			elif uclass == "Ranger": btn_ability.text = "🏹 PIERCING SHOT"
			elif uclass == "Cleric": btn_ability.text = "✨ HEALING LIGHT"

	if hud_unit_info:
		if not selected_unit.is_empty():
			hud_unit_info.text = "%s\nClass: %s\nHP %d/%d   ATK %d   MOVE %d" % [selected_unit["name"], selected_unit["class"], selected_unit["hp"], selected_unit["max_hp"], selected_unit["atk"], selected_unit["move_range"]]
		else:
			hud_unit_info.text = "Click a hero to move, attack, heal or use an ability."

func _get_unit_at(grid_pos: Vector2i) -> Dictionary:
	for unit in active_units:
		if unit["pos"] == grid_pos: return unit
	return {}

func _play_sfx(sfx_name: String) -> void:
	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameState")
		if gs and gs.has_method("play_sfx"): gs.play_sfx(sfx_name)

func _log_telemetry(event_name: String, data: Dictionary) -> void:
	Telemetry.log_event(event_name, "TACTICS", data)

func capture_gameplay_screenshot(save_path: String) -> void:
	var viewport = get_viewport()
	if viewport:
		var img = viewport.get_texture().get_image()
		if img: img.save_png(save_path)

func _spawn_floating_text(text: String, pos: Vector2, color: Color) -> void:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos - Vector2(10, 20)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_outline_color", Color(0,0,0,1))
	lbl.add_theme_constant_override("outline_size", 4)
	add_child(lbl)
	var tw = create_tween()
	tw.tween_property(lbl, "position", lbl.position - Vector2(0, 25), 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.6).set_delay(0.2)
	tw.tween_callback(lbl.queue_free)

func _check_auto_end_phase() -> void:
	if current_turn != "PLAYER": return
	var all_acted = true
	for u in active_units:
		if u["team"] == "PLAYER" and not u["has_acted"]:
			all_acted = false
			break
	if all_acted: _start_enemy_turn()

func _auto_end_unit_if_no_targets(unit: Dictionary) -> void:
	if unit["has_acted"]: return
	var has_target = false
	var atk_r = unit["atk_range"]
	var u_pos = unit["pos"]
	for y in range(-atk_r, atk_r + 1):
		for x in range(-atk_r, atk_r + 1):
			var dist = abs(x) + abs(y)
			if dist <= atk_r and dist > 0:
				var t = u_pos + Vector2i(x, y)
				if board.is_valid_grid(t) and board.has_line_of_sight(u_pos, t):
					var tu = _get_unit_at(t)
					if not tu.is_empty() and tu["team"] != unit["team"]: has_target = true
	if not has_target:
		if unit["class"] == "Cleric": return
		unit["has_acted"] = true
		_deselect_unit()
