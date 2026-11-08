## MovingPlatform — AnimatableBody2D
## Moves back and forth smoothly between initial position and target offset.
extends AnimatableBody2D

@export var move_distance: Vector2 = Vector2(80.0, 0.0)  # Horizontal oscillation by default
@export var speed: float = 1.8  # Oscillation speed multiplier


var _start_position: Vector2 = Vector2.ZERO
var _time: float = 0.0


func _ready() -> void:
	_start_position = global_position


func _physics_process(delta: float) -> void:
	_time += delta * speed
	var factor := (sin(_time) + 1.0) * 0.5  # Oscillates smoothly in range [0, 1]
	global_position = _start_position + move_distance * factor
