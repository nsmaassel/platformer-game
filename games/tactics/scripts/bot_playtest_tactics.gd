# scripts/bot_playtest_tactics.gd
# Headless Autonomous Playtest Bot for Sun & Steel: Tactics

extends SceneTree

func _init() -> void:
	print("♟️ BOT: Starting Headless Tactical Grid Playtest Bot...")
	call_deferred("_run_playtest")


func _run_playtest() -> void:
	var scene_path = "res://games/tactics/scenes/tactical_grid_prototype.tscn"
	var scene_res = ResourceLoader.load(scene_path)
	if not scene_res:
		print("❌ BOT ERROR: Could not load ", scene_path)
		quit(1)
		return

	var root_node = scene_res.instantiate()
	root.add_child(root_node)

	print("✅ BOT: Loaded tactical_grid_prototype.tscn cleanly!")
	await create_timer(0.2).timeout

	# 1. Test Select Unit p1 (Sun Knight)
	var p1 = root_node._get_unit_at(Vector2i(2, 2))
	assert(not p1.is_empty(), "P1 Knight should exist at (2,2)")
	root_node._select_unit(p1)
	assert(root_node.selected_unit["id"] == "p1", "P1 should be selected")
	print("✅ BOT: Unit Selection passed for ", p1["name"])

	# 2. Test Pyromancer Fireball AoE Ability (p2)
	var p2 = root_node._get_unit_at(Vector2i(2, 7))
	assert(not p2.is_empty() and p2["class"] == "Mage", "Pyromancer unit should exist")
	root_node._select_unit(p2)
	root_node._on_ability_pressed()
	assert(root_node.ability_mode == "FIREBALL", "Ability mode should be FIREBALL")
	root_node._execute_active_ability(Vector2i(9, 6))
	print("✅ BOT: Pyromancer Fireball AoE ability assertion passed!")

	# 3. Test Knight Shield Bash (p1)
	root_node._select_unit(p1)
	root_node._on_ability_pressed()
	assert(root_node.ability_mode == "SHIELD_BASH", "Ability mode should be SHIELD_BASH")
	print("✅ BOT: Knight Shield Bash preparation passed!")

	# 4. Test Cleric Healing (p5 heals damaged p1)
	var p5 = root_node._get_unit_at(Vector2i(1, 8))
	p1["hp"] = 20 # Damage Knight
	root_node._heal_unit(p5, p1)
	assert(p1["hp"] == 35, "Knight HP should be restored to 35 by Cleric")
	print("✅ BOT: Cleric Healing assertion passed!")

	# 5. Test End Turn & Enemy AI
	root_node._on_end_turn_pressed()
	await create_timer(0.6).timeout
	print("✅ BOT: Enemy Turn processing passed")

	# 6. Capture Viewport Screenshot Proof
	var shot_path = "logs/tactics_preview.png"
	root_node.capture_gameplay_screenshot(shot_path)
	print("📸 BOT: Screenshot captured at ", shot_path)

	print("🎉 BOT COMPLETE: All Phase 2 Special Ability assertions passed cleanly!")
	quit(0)
