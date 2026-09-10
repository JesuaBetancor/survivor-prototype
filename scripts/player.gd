class_name Player
extends CharacterBody2D

## Player avatar: constant-speed 8-directional movement, drawn as a coloured
## circle placeholder. No sprites or textures anywhere in this prototype.

const SPEED: float = 250.0

@export var radius: float = 16.0
@export var body_color: Color = Color("4fc3f7")
@export var outline_color: Color = Color("e1f5fe")

## Arena rectangle the player is confined to. Set by Main at startup.
var movement_bounds: Rect2 = Rect2()

var _facing: Vector2 = Vector2.RIGHT

@onready var camera: Camera2D = $Camera2D


func _physics_process(_delta: float) -> void:
	# get_vector() already normalises, so diagonals are not faster.
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()

	if movement_bounds.has_area():
		global_position = _clamp_to_bounds(global_position)

	if not direction.is_zero_approx() and direction.dot(_facing) < 0.999:
		_facing = direction
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, body_color, true, -1.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, outline_color, 2.0, true)
	_draw_facing_notch()


## Small triangle marking the last movement direction. Purely a readability aid
## while there is no art; it also previews where directional feedback would go.
func _draw_facing_notch() -> void:
	var tip: Vector2 = _facing * (radius + 7.0)
	var side: Vector2 = _facing.orthogonal() * (radius * 0.45)
	var base: Vector2 = _facing * (radius * 0.6)
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), outline_color)


func _clamp_to_bounds(position_to_clamp: Vector2) -> Vector2:
	return Vector2(
		clampf(position_to_clamp.x, movement_bounds.position.x + radius, movement_bounds.end.x - radius),
		clampf(position_to_clamp.y, movement_bounds.position.y + radius, movement_bounds.end.y - radius)
	)
