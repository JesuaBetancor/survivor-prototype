class_name Spawner
extends Node2D

## Phase 2: manual spawning only, driven by the `spawn_debug` key, so the state
## machine can be inspected in isolation. Phase 4 replaces the input hook with a
## timer; `spawn()` itself stays as-is.

signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var default_type: EnemyType
## How far from the player enemies appear. Wide enough to watch the full
## approach, close enough not to wait for it.
@export var spawn_ring_radius: float = 420.0
@export var debug_burst_count: int = 3

var target: Node2D
var bounds: Rect2


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_debug"):
		for i: int in debug_burst_count:
			spawn(default_type)


func spawn(type: EnemyType) -> Enemy:
	if enemy_scene == null or type == null or not is_instance_valid(target):
		return null

	var enemy: Enemy = enemy_scene.instantiate()
	# Both assigned before add_child so _ready() sees a fully configured enemy.
	enemy.type = type
	enemy.target = target
	enemy.global_position = _pick_spawn_point()

	add_child(enemy)
	enemy_spawned.emit(enemy)
	return enemy


## A random point on a ring around the player, kept inside the arena so enemies
## never spawn outside the playable area.
func _pick_spawn_point() -> Vector2:
	var angle: float = randf() * TAU
	var point: Vector2 = target.global_position + Vector2.from_angle(angle) * spawn_ring_radius

	if bounds.has_area():
		var margin: float = 24.0
		point.x = clampf(point.x, bounds.position.x + margin, bounds.end.x - margin)
		point.y = clampf(point.y, bounds.position.y + margin, bounds.end.y - margin)

	return point
