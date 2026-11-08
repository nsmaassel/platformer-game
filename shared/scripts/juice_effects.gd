## JuiceEffects — Helper class for adding game feel ("juice")
## Handles freeze-frame hit-stops, camera shakes, squash/stretch, and sprite flashing.
class_name JuiceEffects
extends Node

## Executes a brief hit-stop freeze frame by reducing time scale for a fraction of a second
static func freeze_frame(tree: SceneTree, duration_sec: float = 0.05, time_scale: float = 0.05) -> void:
	if tree == null:
		return
	Engine.time_scale = time_scale
	await tree.create_timer(duration_sec * time_scale, true, false, true).timeout
	Engine.time_scale = 1.0


## Shakes a Camera2D node with decaying noise intensity
static func shake_camera(camera: Camera2D, intensity: float = 8.0, duration: float = 0.2) -> void:
	if camera == null or not is_instance_valid(camera) or not camera.is_inside_tree():
		return
	var tree := camera.get_tree()
	if tree == null:
		return
	var elapsed := 0.0
	var original_offset := camera.offset

	while elapsed < duration:
		var current_intensity := intensity * (1.0 - (elapsed / duration))
		camera.offset = original_offset + Vector2(
			randf_range(-current_intensity, current_intensity),
			randf_range(-current_intensity, current_intensity)
		)
		await tree.process_frame
		elapsed += tree.get_process_delta_time()

	camera.offset = original_offset


## Applies squash & stretch scaling tween to a Node2D
static func squash_and_stretch(node: Node2D, scale_amount: Vector2 = Vector2(1.2, 0.8), duration: float = 0.15) -> void:
	if node == null or not is_instance_valid(node) or not node.is_inside_tree():
		return
	var tree := node.get_tree()
	if tree == null:
		return

	var original_scale := node.scale
	var tween := node.create_tween()
	if tween != null:
		tween.tween_property(node, "scale", scale_amount, duration * 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(node, "scale", original_scale, duration * 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Modulates a CanvasItem sprite with a flash color briefly
static func flash_sprite(sprite: CanvasItem, flash_color: Color = Color(2.0, 2.0, 2.0, 1.0), duration: float = 0.1) -> void:
	if sprite == null or not is_instance_valid(sprite) or not sprite.is_inside_tree():
		return
	var tree := sprite.get_tree()
	if tree == null:
		return
	var original_modulate := sprite.modulate
	sprite.modulate = flash_color
	await tree.create_timer(duration, true, false, true).timeout
	if is_instance_valid(sprite):
		sprite.modulate = original_modulate
