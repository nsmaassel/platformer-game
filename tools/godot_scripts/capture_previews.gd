## capture_previews.gd — Headless visual preview generator
## Renders each level_*.tscn to a PNG image in logs/ for visual verification.
## Run: godot --headless --path . --script scripts/capture_previews.gd
extends SceneTree

func _init() -> void:
	var dir := DirAccess.open("res://games/platformer/scenes/")
	if dir == null:
		print("CAPTURE: Cannot open res://games/platformer/scenes/")
		quit(1)
		return

	var level_files: Array[String] = []
	dir.list_dir_begin()
	var fname := dir.get_next()
	while fname != "":
		if fname.begins_with("level_") and fname.ends_with(".tscn"):
			level_files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	level_files.sort()

	print("CAPTURE: Found %d level(s) to render" % level_files.size())

	for file_name in level_files:
		var scene_path := "res://games/platformer/scenes/" + file_name
		var scene := load(scene_path) as PackedScene
		if scene == null:
			print("CAPTURE: Failed to load %s" % scene_path)
			continue

		var vp := SubViewport.new()
		vp.size = Vector2i(480, 270)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS

		var level_instance := scene.instantiate()
		vp.add_child(level_instance)
		root.add_child(vp)

		var img := vp.get_texture().get_image()
		if img != null:
			var out_name := file_name.replace(".tscn", "_preview.png")
			var out_path := ProjectSettings.globalize_path("res://logs/" + out_name)
			img.save_png(out_path)
			print("  SAVED: %s (%dx%d)" % [out_path, img.get_width(), img.get_height()])
		else:
			print("  FAILED: Could not capture image for %s" % file_name)

		vp.queue_free()

	print("CAPTURE: Complete!")
	quit(0)

