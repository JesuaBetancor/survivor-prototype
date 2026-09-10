class_name HealthPips
extends Control

## Health readout drawn as circles rather than text or an icon font: the whole
## prototype is geometric shapes, and it sidesteps missing-glyph risk.

@export var pip_radius: float = 9.0
@export var pip_spacing: float = 26.0
@export var full_color: Color = Color("ff5252")
@export var empty_color: Color = Color(1, 1, 1, 0.18)

var _current: int = 0
var _maximum: int = 0


func set_health(current: int, maximum: int) -> void:
	_current = current
	_maximum = maximum
	queue_redraw()


func _draw() -> void:
	for i: int in _maximum:
		var centre: Vector2 = Vector2(pip_radius + i * pip_spacing, pip_radius)
		if i < _current:
			draw_circle(centre, pip_radius, full_color, true, -1.0, true)
		else:
			draw_arc(centre, pip_radius, 0.0, TAU, 24, empty_color, 2.0, true)
