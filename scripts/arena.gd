class_name Arena
extends Node2D

## Static playfield: a grid and a border drawn behind everything else, so that
## player movement reads as movement instead of a circle floating in the void.

@export var size: Vector2 = Vector2(2400.0, 1600.0)
@export var grid_step: float = 120.0
@export var grid_color: Color = Color(1.0, 1.0, 1.0, 0.05)
@export var border_color: Color = Color(1.0, 1.0, 1.0, 0.18)


## Arena rectangle in global space, centred on this node.
func get_bounds() -> Rect2:
	return Rect2(global_position - size * 0.5, size)


func _draw() -> void:
	var half: Vector2 = size * 0.5

	var x: float = -half.x
	while x <= half.x:
		draw_line(Vector2(x, -half.y), Vector2(x, half.y), grid_color, 1.0)
		x += grid_step

	var y: float = -half.y
	while y <= half.y:
		draw_line(Vector2(-half.x, y), Vector2(half.x, y), grid_color, 1.0)
		y += grid_step

	draw_rect(Rect2(-half, size), border_color, false, 3.0)
