class_name HeroClassData
extends Resource

## Base stats for one hero class (Sun Knight, Pyromancer, Frost Blade, Ranger, Cleric) or enemy type.

@export var display_name: String = "Recruit"
@export var max_hp: int = 100
@export var max_ap: int = 4
@export var move_range: int = 4
@export var attack_power: int = 15
@export var armor: int = 5
@export var speed: int = 10
@export var description: String = ""
@export var sprite_texture: Texture2D


func _init(
	p_name: String = "Recruit",
	p_hp: int = 100,
	p_ap: int = 4,
	p_move: int = 4,
	p_atk: int = 15,
	p_armor: int = 5,
	p_speed: int = 10
) -> void:
	display_name = p_name
	max_hp = p_hp
	max_ap = p_ap
	move_range = p_move
	attack_power = p_atk
	armor = p_armor
	speed = p_speed
