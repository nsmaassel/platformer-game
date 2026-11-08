## ClassPromotionUI — Fire Emblem style Class Promotion Overlay
## Displays class promotion banner, stat growth preview, class selection buttons, and triumph SFX.
class_name ClassPromotionUI
extends CanvasLayer

signal promotion_selected(new_class_name: String, atk_bonus: int, hp_bonus: int)

@onready var panel: Panel = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var desc_label: Label = $Panel/VBox/DescLabel
@onready var btn_pyro: Button = $Panel/VBox/HBox/BtnPyromancer
@onready var btn_blade: Button = $Panel/VBox/HBox/BtnSpellblade

var is_active: bool = false


func _ready() -> void:
	visible = false
	if btn_pyro != null:
		btn_pyro.pressed.connect(_on_pyromancer_chosen)
	if btn_blade != null:
		btn_blade.pressed.connect(_on_spellblade_chosen)


func open_promotion() -> void:
	visible = true
	is_active = true
	GameState.play_sfx("win")


func _on_pyromancer_chosen() -> void:
	visible = false
	is_active = false
	GameState.play_sfx("powerup")
	promotion_selected.emit("Pyromancer", 20, 20)


func _on_spellblade_chosen() -> void:
	visible = false
	is_active = false
	GameState.play_sfx("powerup")
	promotion_selected.emit("Spellblade", 14, 40)
