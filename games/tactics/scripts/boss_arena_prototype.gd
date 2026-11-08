# scripts/boss_arena_prototype.gd
# Hero vs. Boss Battle Arena Prototype (Sun & Steel)
# Fully Iterated: 10 Passes of Combat Feel, FX, Lighting, SFX, Magma Mortars, & Stance Execution

extends Node2D

const JuiceEffects = preload("res://shared/scripts/juice_effects.gd")
const Telemetry = preload("res://shared/scripts/telemetry.gd")



# Loadout state
var current_spirit: String = "Flame" # "Flame" or "Frost"
var player_hp: int = 120
var max_hp: int = 120
var player_atk: int = 15
var move_speed: float = 160.0

# Boss State
var boss_max_hp: int = 350
var boss_hp: int = 350
var boss_phase: int = 1
var boss_state: String = "idle" # "idle", "telegraph_slam", "telegraph_cleave", "attacking", "staggered", "recovering"
var boss_timer: float = 0.0
var boss_stagger_timer: float = 0.0
var stance_break_meter: float = 0.0 # Reaches 100 -> Stagger!
var mortar_timer: float = 0.0 # Phase 2 Magma Mortars

# Nodes
@onready var player: Sprite2D = $Player
@onready var boss: Sprite2D = $Boss
@onready var boss_hp_bar: ProgressBar = $CanvasLayer/BossHPBar
@onready var boss_name_label: Label = $CanvasLayer/BossNameLabel
@onready var boss_telegraph_circle: ColorRect = $TelegraphCircle
@onready var boss_telegraph_cone: ColorRect = $TelegraphCone
@onready var boss_light: PointLight2D = $Boss/PointLight2D

@onready var slash_arc_sprite: Sprite2D = $Player/SlashArc
@onready var execute_label: Label = $CanvasLayer/ExecuteLabel
@onready var hud_status: Label = $CanvasLayer/HUDStatus
@onready var hud_loadout: Label = $CanvasLayer/HUDLoadout
@onready var hud_guide: Label = $CanvasLayer/HUDGuide
@onready var victory_banner: Label = $CanvasLayer/VictoryBanner
@onready var camera: Camera2D = $Camera2D

# Debounce & Cooldown buffers
var dash_cooldown: float = 0.0
var special_cooldown: float = 0.0
var attack_cooldown: float = 0.0
var spirit_swap_cooldown: float = 0.0

var tex_hero_apprentice: Texture2D
var tex_hero_pyro: Texture2D
var tex_hero_blade: Texture2D
var tex_boss: Texture2D
var tex_slash_arc: Texture2D
var tex_fire_cleave: Texture2D
var tex_frost_wave: Texture2D
var tex_mortar: Texture2D

var aim_direction: Vector2 = Vector2.RIGHT


func _ensure_nodes() -> void:
	if player == null: player = get_node_or_null("Player")
	if boss == null: boss = get_node_or_null("Boss")
	if camera == null: camera = get_node_or_null("Camera2D")
	if boss_hp_bar == null: boss_hp_bar = get_node_or_null("CanvasLayer/BossHPBar")
	if boss_name_label == null: boss_name_label = get_node_or_null("CanvasLayer/BossNameLabel")
	if boss_telegraph_circle == null: boss_telegraph_circle = get_node_or_null("TelegraphCircle")
	if boss_telegraph_cone == null: boss_telegraph_cone = get_node_or_null("TelegraphCone")
	if boss_light == null: boss_light = get_node_or_null("Boss/PointLight2D")
	if slash_arc_sprite == null: slash_arc_sprite = get_node_or_null("Player/SlashArc")
	if execute_label == null: execute_label = get_node_or_null("CanvasLayer/ExecuteLabel")
	if hud_status == null: hud_status = get_node_or_null("CanvasLayer/HUDStatus")
	if hud_loadout == null: hud_loadout = get_node_or_null("CanvasLayer/HUDLoadout")
	if hud_guide == null: hud_guide = get_node_or_null("CanvasLayer/HUDGuide")
	if victory_banner == null: victory_banner = get_node_or_null("CanvasLayer/VictoryBanner")


func _ready() -> void:
	_ensure_nodes()
	_load_textures()
	if boss_telegraph_circle: boss_telegraph_circle.visible = false
	if boss_telegraph_cone: boss_telegraph_cone.visible = false
	if victory_banner: victory_banner.visible = false
	if execute_label: execute_label.visible = false
	if slash_arc_sprite: slash_arc_sprite.visible = false
	_log_telemetry("ARENA_START", {"player_hp": player_hp, "boss_hp": boss_hp})
	_update_hud()


var tex_hero_atk0: Texture2D
var tex_hero_atk1: Texture2D
var tex_hero_atk2: Texture2D

func _load_textures() -> void:
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_apprentice.png"):
		tex_hero_apprentice = load("res://games/tactics/assets/sprites/shrine/hero_apprentice.png")
		if player: player.texture = tex_hero_apprentice
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_pyromancer.png"):
		tex_hero_pyro = load("res://games/tactics/assets/sprites/shrine/hero_pyromancer.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_spellblade.png"):
		tex_hero_blade = load("res://games/tactics/assets/sprites/shrine/hero_spellblade.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_attack_0.png"):
		tex_hero_atk0 = load("res://games/tactics/assets/sprites/shrine/hero_attack_0.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_attack_1.png"):
		tex_hero_atk1 = load("res://games/tactics/assets/sprites/shrine/hero_attack_1.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/hero_attack_2.png"):
		tex_hero_atk2 = load("res://games/tactics/assets/sprites/shrine/hero_attack_2.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/guardian.png"):
		tex_boss = load("res://games/tactics/assets/sprites/shrine/guardian.png")
		if boss: boss.texture = tex_boss
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/slash_arc.png"):
		tex_slash_arc = load("res://games/tactics/assets/sprites/shrine/slash_arc.png")
		if slash_arc_sprite: slash_arc_sprite.texture = tex_slash_arc
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/fire_cleave.png"):
		tex_fire_cleave = load("res://games/tactics/assets/sprites/shrine/fire_cleave.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/frost_wave.png"):
		tex_frost_wave = load("res://games/tactics/assets/sprites/shrine/frost_wave.png")
	if ResourceLoader.exists("res://games/tactics/assets/sprites/shrine/magma_mortar.png"):
		tex_mortar = load("res://games/tactics/assets/sprites/shrine/magma_mortar.png")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and attack_cooldown <= 0.0:
			attack_cooldown = 0.25
			_execute_attack(player_atk, "Slash (LMB)")
		elif event.button_index == MOUSE_BUTTON_RIGHT and special_cooldown <= 0.0:
			special_cooldown = 2.0
			var bonus_dmg = 45 if current_spirit == "Flame" else 35
			_execute_attack(player_atk + bonus_dmg, "Special (RMB)")


func _physics_process(delta: float) -> void:
	_ensure_nodes()

	dash_cooldown = max(0.0, dash_cooldown - delta)
	special_cooldown = max(0.0, special_cooldown - delta)
	attack_cooldown = max(0.0, attack_cooldown - delta)
	spirit_swap_cooldown = max(0.0, spirit_swap_cooldown - delta)

	_update_aim_direction()
	_handle_player_movement(delta)
	_handle_player_keyboard_actions()
	_update_boss_ai(delta)
	_update_hud()

	if Input.is_key_pressed(KEY_F12):
		capture_gameplay_screenshot("logs/gameplay_boss_frame.png")


func _update_aim_direction() -> void:
	if player == null: return
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - player.position).normalized()
	if dir != Vector2.ZERO:
		aim_direction = dir
		player.flip_h = (aim_direction.x < 0.0)


var last_move_vec: Vector2 = Vector2.ZERO

func _handle_player_movement(delta: float) -> void:
	if player == null: return

	var move_vec = Vector2.ZERO
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D): move_vec.x += 1.0
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A): move_vec.x -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S): move_vec.y += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W): move_vec.y -= 1.0

	if move_vec != Vector2.ZERO:
		move_vec = move_vec.normalized()
		last_move_vec = move_vec
		player.position += move_vec * move_speed * delta

	player.position.x = clamp(player.position.x, 30.0, 450.0)
	player.position.y = clamp(player.position.y, 40.0, 240.0)


func _handle_player_keyboard_actions() -> void:
	# Intuitive Dash Direction: Uses movement direction if moving, otherwise aims towards mouse!
	if (Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_SHIFT) or Input.is_key_pressed(KEY_ALT)) and dash_cooldown <= 0.0:
		dash_cooldown = 0.5
		var dash_dir = last_move_vec if last_move_vec != Vector2.ZERO else aim_direction
		if player:
			_spawn_dash_afterimages(player.position, dash_dir)
			player.position += dash_dir * 55.0
		JuiceEffects.squash_and_stretch(player, Vector2(1.3, 0.7), 0.15)
		_play_sfx("jump")
		_log_telemetry("ACTION_DASH", {"dash_dir": dash_dir, "player_pos": player.position if player else Vector2.ZERO})

	# Swap Spirit Gem (SFX + Flash)
	if (Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_Q)) and spirit_swap_cooldown <= 0.0:
		spirit_swap_cooldown = 0.35
		if current_spirit == "Flame":
			current_spirit = "Frost"
			if tex_hero_blade and player: player.texture = tex_hero_blade
		else:
			current_spirit = "Flame"
			if tex_hero_pyro and player: player.texture = tex_hero_pyro
		JuiceEffects.flash_sprite(player, Color(1, 1, 1), 0.1)
		_play_sfx("powerup")
		_log_telemetry("SPIRIT_SWAP", {"new_spirit": current_spirit})

	if Input.is_key_pressed(KEY_J) and attack_cooldown <= 0.0:
		attack_cooldown = 0.25
		_execute_attack(player_atk, "Slash (Key J)")

	if (Input.is_key_pressed(KEY_K) or Input.is_key_pressed(KEY_Z)) and special_cooldown <= 0.0:
		special_cooldown = 2.0
		var bonus_dmg = 45 if current_spirit == "Flame" else 35
		_execute_attack(player_atk + bonus_dmg, "Special (Key K)")


func _spawn_dash_afterimages(start_pos: Vector2, dash_dir: Vector2) -> void:
	for i in range(3):
		var ghost = Sprite2D.new()
		ghost.texture = player.texture if player else tex_hero_apprentice
		ghost.position = start_pos + (dash_dir * (i * 15.0))
		ghost.modulate = Color(0.4, 0.7, 1.0, 0.5 - (i * 0.15))
		add_child(ghost)
		var tween = create_tween()
		if tween:
			tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
			tween.tween_callback(ghost.queue_free)


var ignite_stacks: int = 0
var tex_thermal_fracture: Texture2D

func _execute_attack(dmg: int, type: String) -> void:
	_ensure_nodes()
	JuiceEffects.squash_and_stretch(player, Vector2(1.2, 0.8), 0.1)
	_play_sfx("hit")

	# Multi-frame Attack Animation Sequence (Windup -> Impact -> Recovery)
	if player and tex_hero_atk0 and tex_hero_atk1 and tex_hero_atk2:
		player.texture = tex_hero_atk0
		var anim_tween = create_tween()
		if anim_tween:
			anim_tween.tween_interval(0.05)
			anim_tween.tween_callback(func(): if player: player.texture = tex_hero_atk1)
			anim_tween.tween_interval(0.08)
			anim_tween.tween_callback(func(): if player: player.texture = tex_hero_atk2)
			anim_tween.tween_interval(0.06)
			anim_tween.tween_callback(func():
				if player:
					player.texture = tex_hero_blade if current_spirit == "Frost" else (tex_hero_pyro if current_spirit == "Flame" else tex_hero_apprentice)
			)

	# Slash Arc Visual FX & Particle Emitter
	if slash_arc_sprite:
		slash_arc_sprite.visible = true
		slash_arc_sprite.rotation = aim_direction.angle()
		var tween = create_tween()
		if tween:
			tween.tween_property(slash_arc_sprite, "modulate:a", 0.0, 0.15)
			tween.tween_callback(func():
				slash_arc_sprite.visible = false
				slash_arc_sprite.modulate.a = 1.0
			)

	var slash_particles = player.get_node_or_null("SlashParticles") as CPUParticles2D
	if slash_particles:
		slash_particles.direction = aim_direction
		slash_particles.restart()

	if player == null or boss == null: return
	var dist = player.position.distance_to(boss.position)
	_log_telemetry("PLAYER_ATTACK", {"type": type, "dmg": dmg, "dist_to_boss": dist})

	if dist < 75.0:
		# Trigger Hit Sparks Particle Burst
		var hit_sparks = boss.get_node_or_null("HitSparks") as CPUParticles2D
		if hit_sparks:
			hit_sparks.color = Color(1, 0.4, 0.1) if current_spirit == "Flame" else Color(0.4, 0.9, 1.0)
			hit_sparks.restart()
		# Check Thermal Reaction Synergy (Flame Ignite + Frost Detonation)
		var total_dmg = dmg
		if current_spirit == "Flame":
			ignite_stacks = min(3, ignite_stacks + 1)
			_log_telemetry("IGNITE_STACK_ADDED", {"stacks": ignite_stacks})
		elif current_spirit == "Frost" and ignite_stacks > 0:
			# ⚡ THERMAL FRACTURE DETONATION ⚡
			total_dmg += 80
			_trigger_thermal_fracture_explosion()
			ignite_stacks = 0

		# Deal damage & Smooth Boss Knockback
		boss_hp = max(0, boss_hp - total_dmg)
		var target_boss_pos = boss.position + (aim_direction * 10.0)
		target_boss_pos.x = clamp(target_boss_pos.x, 50.0, 430.0)
		target_boss_pos.y = clamp(target_boss_pos.y, 50.0, 220.0)
		
		var kb_tween = create_tween()
		if kb_tween:
			kb_tween.tween_property(boss, "position", target_boss_pos, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		JuiceEffects.flash_sprite(boss, Color(1, 0.2, 0.2), 0.12)
		
		# Build Stance Break Meter
		stance_break_meter += 25.0
		_log_telemetry("BOSS_HIT", {"boss_hp": boss_hp, "stance_meter": stance_break_meter})

		if stance_break_meter >= 100.0:
			_trigger_stance_break()
		
		if boss_hp <= 0:
			_on_boss_defeated()
		elif boss_hp <= boss_max_hp / 2 and boss_phase == 1:
			_trigger_phase_two()


func _trigger_thermal_fracture_explosion() -> void:
	if boss == null: return
	_trigger_stance_break()
	JuiceEffects.shake_camera(camera, 12.0, 0.3)
	_play_sfx("coin")
	if execute_label:
		execute_label.text = "⚡ THERMAL FRACTURE DETONATED (+80 DAMAGE & STANCE BREAK!) ⚡"
		execute_label.visible = true
	_log_telemetry("THERMAL_FRACTURE_DETONATED", {"boss_pos": boss.position})


func _update_boss_ai(delta: float) -> void:
	if boss_hp <= 0: return

	boss_timer += delta

	# Pass 4: Phase 2 Magma Mortars
	if boss_phase == 2:
		mortar_timer += delta
		if mortar_timer >= 3.0:
			mortar_timer = 0.0
			_launch_magma_mortar()

	match boss_state:
		"idle":
			if boss_timer >= (1.5 if boss_phase == 1 else 0.9):
				boss_timer = 0.0
				if randf() > 0.5:
					_start_telegraph_slam()
				else:
					_start_telegraph_cleave()

		"telegraph_slam":
			if boss_telegraph_circle and player:
				boss_telegraph_circle.visible = true
				boss_telegraph_circle.position = player.position - Vector2(30, 30)
			if boss_timer >= (0.8 if boss_phase == 1 else 0.5):
				if boss_telegraph_circle: boss_telegraph_circle.visible = false
				_execute_boss_slam()

		"telegraph_cleave":
			if boss_telegraph_cone and boss:
				boss_telegraph_cone.visible = true
				boss_telegraph_cone.position = boss.position - Vector2(40, 20)
			if boss_timer >= (0.8 if boss_phase == 1 else 0.5):
				if boss_telegraph_cone: boss_telegraph_cone.visible = false
				_execute_boss_cleave()

		"recovering":
			if boss_timer >= 1.0:
				boss_state = "idle"
				boss_timer = 0.0

		"staggered":
			boss_stagger_timer -= delta
			if boss_stagger_timer <= 0.0:
				boss_state = "idle"
				boss_timer = 0.0
				if boss: boss.modulate = Color(1, 1, 1)
				if execute_label: execute_label.visible = false
				_log_telemetry("STANCE_RECOVERED", {})


func _launch_magma_mortar() -> void:
	if player == null or tex_mortar == null: return
	var mortar = Sprite2D.new()
	mortar.texture = tex_mortar
	mortar.position = boss.position if boss else Vector2(240, 110)
	add_child(mortar)

	var target_pos = player.position
	var tween = create_tween()
	if tween:
		tween.tween_property(mortar, "position", target_pos, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func():
			JuiceEffects.shake_camera(camera, 5.0, 0.15)
			if player and player.position.distance_to(target_pos) < 30.0:
				_damage_player(15)
			mortar.queue_free()
		)
	_log_telemetry("MAGMA_MORTAR_LAUNCHED", {"target": target_pos})


func _start_telegraph_slam() -> void:
	boss_state = "telegraph_slam"
	boss_timer = 0.0
	_log_telemetry("TELEGRAPH_SLAM_START", {"pos": player.position if player else Vector2.ZERO})


func _start_telegraph_cleave() -> void:
	boss_state = "telegraph_cleave"
	boss_timer = 0.0
	_log_telemetry("TELEGRAPH_CLEAVE_START", {"pos": boss.position if boss else Vector2.ZERO})


func _execute_boss_slam() -> void:
	boss_state = "recovering"
	boss_timer = 0.0
	JuiceEffects.shake_camera(camera, 8.0, 0.2)
	
	if player and boss_telegraph_circle:
		var dist = player.position.distance_to(boss_telegraph_circle.position + Vector2(30, 30))
		if dist < 35.0:
			_damage_player(25)


func _execute_boss_cleave() -> void:
	boss_state = "recovering"
	boss_timer = 0.0
	JuiceEffects.shake_camera(camera, 6.0, 0.15)
	
	if player and boss:
		var dist = player.position.distance_to(boss.position)
		if dist < 55.0:
			_damage_player(20)


func _damage_player(dmg: int) -> void:
	player_hp = max(0, player_hp - dmg)
	JuiceEffects.flash_sprite(player, Color(1, 0, 0), 0.2)
	if is_inside_tree() and get_tree(): JuiceEffects.freeze_frame(get_tree(), 0.08)
	_log_telemetry("PLAYER_DAMAGED", {"player_hp": player_hp, "dmg": dmg})


func _trigger_stance_break() -> void:
	stance_break_meter = 0.0
	boss_state = "staggered"
	boss_stagger_timer = 3.0
	if boss: boss.modulate = Color(0.4, 0.8, 1.0) # Frozen blue stance break
	if execute_label: execute_label.visible = true
	JuiceEffects.shake_camera(camera, 10.0, 0.3)
	_play_sfx("coin")
	_log_telemetry("STANCE_BREAK_TRIGGERED", {})


func _trigger_phase_two() -> void:
	boss_phase = 2
	if boss_name_label: boss_name_label.text = "🔥 SUNKEN GOLEM — PHASE 2 (MAGMA ENRAGED) 🔥"
	if boss_light:
		boss_light.enabled = true
		boss_light.energy = 2.5
	JuiceEffects.shake_camera(camera, 12.0, 0.4)
	_play_sfx("powerup")
	_log_telemetry("PHASE_TWO_TRIGGERED", {})


func _on_boss_defeated() -> void:
	if boss: boss.visible = false
	if victory_banner: victory_banner.visible = true
	if execute_label: execute_label.visible = false
	JuiceEffects.shake_camera(camera, 15.0, 0.5)
	_play_sfx("coin")
	_log_telemetry("BOSS_DEFEATED", {})


func _update_hud() -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = boss_max_hp
		boss_hp_bar.value = boss_hp

	if hud_status:
		hud_status.text = "HERO HP: %d/%d  |  STANCE BREAK METER: %d%%" % [player_hp, max_hp, int(stance_break_meter)]

	if hud_loadout:
		var spec_cd_text = "READY" if special_cooldown <= 0.0 else "%.1fs" % special_cooldown
		hud_loadout.text = "AIM: [Mouse] | SPIRIT: [%s] (E/Q) | LMB/[J]: Attack | RMB/[K]: Special (%s) | [Space]: Dash" % [current_spirit, spec_cd_text]


func _play_sfx(sfx_name: String) -> void:
	if is_inside_tree() and get_tree() and get_tree().root:
		var gs = get_tree().root.get_node_or_null("GameState")
		if gs and gs.has_method("play_sfx"):
			gs.play_sfx(sfx_name)


func _log_telemetry(event_name: String, data: Dictionary) -> void:
	Telemetry.log_event(event_name, "BOSS_ARENA", data)


func capture_gameplay_screenshot(save_path: String) -> void:
	var viewport = get_viewport()
	if viewport:
		var img = viewport.get_texture().get_image()
		if img:
			img.save_png(save_path)
			print("📸 Viewport frame screenshot saved: ", save_path)
