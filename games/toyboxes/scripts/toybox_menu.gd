## ToyboxMenu — Main Hub for testing all 4 GBC/GBA opus game concepts
extends Control

@onready var title_label: Label = $VBox/TitleLabel
@onready var desc_label: Label = $VBox/DescLabel


func _ready() -> void:
	if not InputMap.has_action("move_up"):
		_add_default_input_actions()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn")
	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_a.tscn")
			KEY_2:
				get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_b.tscn")
			KEY_3:
				get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_c.tscn")
			KEY_4:
				get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_d.tscn")
			KEY_5, KEY_0:
				get_tree().change_scene_to_file("res://games/tactics/scenes/sun_steel_prototype.tscn")


func _on_btn_sun_steel_pressed() -> void:
	get_tree().change_scene_to_file("res://games/tactics/scenes/sun_steel_prototype.tscn")


func _on_btn_concept_a_pressed() -> void:
	get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_a.tscn")


func _on_btn_concept_b_pressed() -> void:
	get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_b.tscn")


func _on_btn_concept_c_pressed() -> void:
	get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_c.tscn")


func _on_btn_concept_d_pressed() -> void:
	get_tree().change_scene_to_file("res://games/toyboxes/scenes/toybox_concept_d.tscn")


func _on_btn_back_pressed() -> void:
	get_tree().change_scene_to_file("res://games/platformer/scenes/main_menu.tscn")


func _add_default_input_actions() -> void:
	# Fallback runtime key mappings if project.godot doesn't have them
	var up_ev := InputEventKey.new()
	up_ev.physical_keycode = KEY_W
	InputMap.add_action("move_up")
	InputMap.action_add_event("move_up", up_ev)

	var down_ev := InputEventKey.new()
	down_ev.physical_keycode = KEY_S
	InputMap.add_action("move_down")
	InputMap.action_add_event("move_down", down_ev)
