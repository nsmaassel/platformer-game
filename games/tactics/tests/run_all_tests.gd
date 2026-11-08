# games/tactics/tests/run_all_tests.gd
## Headless GDScript Test Runner for Tactics Game
## Discovers and executes all test_*.gd scripts in games/tactics/tests/
## Registered test suites: test_combat_manager.gd, test_tactical_ai.gd, test_party_loadout.gd, test_campaign_flow.gd
extends SceneTree


func _init() -> void:
	print("==========================================")
	print("=== Running Tactics GDScript Test Suite ===")
	print("==========================================")
	print("")

	var test_dir := "res://games/tactics/tests/"
	var dir := DirAccess.open(test_dir)
	var test_files: Array[String] = []

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.begins_with("test_") and file_name.ends_with(".gd"):
				test_files.append(test_dir + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	else:
		print("❌ ERROR: Could not open test directory: %s" % test_dir)
		quit(1)
		return

	test_files.sort()

	if test_files.is_empty():
		print("❌ ERROR: No test_*.gd files found in %s" % test_dir)
		quit(1)
		return

	var total_tests := 0
	var passed_tests := 0
	var failed_tests := 0

	for file_path in test_files:
		print("--- Running Test Suite: %s ---" % file_path.get_file())
		var script = load(file_path)
		if not script:
			print("❌ Failed to load test script: %s" % file_path)
			failed_tests += 1
			continue

		var instance = script.new()
		if not instance:
			print("❌ Failed to instantiate test script: %s" % file_path)
			failed_tests += 1
			continue

		var methods: Array[String] = []
		for m in instance.get_method_list():
			var m_name: String = m["name"]
			if m_name.begins_with("test_"):
				methods.append(m_name)

		methods.sort()

		if methods.is_empty():
			print("⚠️ Warning: No test methods found in %s" % file_path.get_file())
			continue

		for method_name in methods:
			total_tests += 1
			print("  • Running %s..." % method_name)
			instance.call(method_name)

			var method_failed := false
			if instance.get("errors") != null:
				var errs: Array = instance.get("errors")
				if not errs.is_empty():
					method_failed = true
					failed_tests += 1
					errs.clear()

			if not method_failed:
				passed_tests += 1
				print("    ✅ %s PASSED" % method_name)

	print("")
	print("==========================================")
	print("TEST SUMMARY: %d passed, %d failed out of %d total" % [passed_tests, failed_tests, total_tests])
	print("==========================================")

	if failed_tests > 0 or total_tests == 0:
		quit(1)
	else:
		quit(0)
