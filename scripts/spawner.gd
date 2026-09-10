class_name Spawner
extends Node2D

## Automatic wave spawning. Cadence tightens over the run, and the spawn ring
## sits outside the viewport so enemies walk in rather than popping into view.

signal enemy_spawned(enemy: Enemy)

@export var enemy_scene: PackedScene
@export var default_type: EnemyType

@export_group("Cadence")
## Seconds between spawns at the very start of a run.
@export var base_interval: float = 1.2
## Floor on the interval, however long the run goes.
@export var min_interval: float = 0.12
## How long the ramp from base to min takes.
@export var ramp_seconds: float = 240.0
## Hard cap on live enemies. There is no defeat condition until phase 5, so
## without this an idle run climbs until the framerate dies.
@export var max_alive: int = 220

@export_group("Placement")
## Beyond the 1280x720 viewport's half-diagonal (~734 px), so enemies appear
## off-screen. Jitter keeps them from arriving in a clean circle.
@export var spawn_ring_radius: float = 820.0
@export var spawn_ring_jitter: float = 70.0

@export_group("Debug")
## Kept from phase 2: handy for forcing a crowd instead of waiting for the ramp.
@export var debug_burst_count: int = 3

var target: Node2D
var bounds: Rect2
var spawning_enabled: bool = true
## Run clock, owned by Main so the HUD and the cadence never drift apart.
var run_time: float = 0.0

var alive_count: int = 0
var _accumulator: float = 0.0


## Fixed timestep: the cadence is gameplay, so it should not depend on how fast
## the machine happens to be rendering.
func _physics_process(delta: float) -> void:
	if not spawning_enabled:
		return

	_accumulator += delta
	var interval: float = current_interval()
	while _accumulator >= interval:
		_accumulator -= interval
		if alive_count < max_alive:
			spawn(default_type)
		interval = current_interval()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("spawn_debug"):
		for i: int in debug_burst_count:
			spawn(default_type)


## Interpolating the spawn *rate* rather than the interval keeps the opening
## minute gentle and makes the late ramp bite; squaring the progress delays the
## bite further still.
func current_interval() -> float:
	var progress: float = clampf(run_time / ramp_seconds, 0.0, 1.0)
	var rate: float = lerpf(1.0 / base_interval, 1.0 / min_interval, progress * progress)
	return 1.0 / rate


func spawn(type: EnemyType) -> Enemy:
	if enemy_scene == null or type == null or not is_instance_valid(target):
		return null

	var enemy: Enemy = enemy_scene.instantiate()
	# Both assigned before add_child so _ready() sees a fully configured enemy.
	enemy.type = type
	enemy.target = target
	enemy.global_position = _pick_spawn_point()
	enemy.died.connect(_on_enemy_died)

	add_child(enemy)
	alive_count += 1
	enemy_spawned.emit(enemy)
	return enemy


func _on_enemy_died(_enemy: Enemy, _xp: int) -> void:
	alive_count -= 1


## A jittered point on a ring around the player, kept inside the arena so
## enemies never spawn outside the playable area.
func _pick_spawn_point() -> Vector2:
	var angle: float = randf() * TAU
	var distance: float = spawn_ring_radius + randf_range(-spawn_ring_jitter, spawn_ring_jitter)
	var point: Vector2 = target.global_position + Vector2.from_angle(angle) * distance

	if bounds.has_area():
		var margin: float = 24.0
		point.x = clampf(point.x, bounds.position.x + margin, bounds.end.x - margin)
		point.y = clampf(point.y, bounds.position.y + margin, bounds.end.y - margin)

	return point
