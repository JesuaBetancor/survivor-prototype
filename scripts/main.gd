extends Node2D

## Root of the gameplay scene. For now it only wires the arena bounds into the
## player and its camera; spawning and HUD arrive in later phases.

@onready var arena: Arena = $Arena
@onready var player: Player = $Player


func _ready() -> void:
	var bounds: Rect2 = arena.get_bounds()
	player.movement_bounds = bounds
	_apply_camera_limits(player.camera, bounds)


## Keeps the camera from showing the void outside the arena.
func _apply_camera_limits(camera: Camera2D, bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
