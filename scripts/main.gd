extends Node2D

## Root of the gameplay scene. Owns the run clock, wires the arena bounds into
## the player, the camera and the spawner, and drives the HUD.

@onready var arena: Arena = $Arena
@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var time_label: Label = $HUD/TimeLabel
@onready var debug_label: Label = $HUD/DebugLabel
@onready var health_pips: HealthPips = $HUD/HealthPips
@onready var game_over: Control = $HUD/GameOver

## Single source of truth for elapsed survival time: both the HUD and the spawn
## cadence read it, so the clock on screen always matches the pressure.
var run_time: float = 0.0

var _kills: int = 0
var _hits_taken: int = 0
var _pulses: int = 0
var _pulses_connected: int = 0


func _ready() -> void:
	var bounds: Rect2 = arena.get_bounds()

	player.movement_bounds = bounds
	player.parry_pulsed.connect(_on_parry_pulsed)
	player.health_changed.connect(health_pips.set_health)
	player.died.connect(_on_player_died)
	health_pips.set_health(player.health, player.max_health)
	_apply_camera_limits(player.camera, bounds)

	spawner.target = player
	spawner.bounds = bounds
	spawner.enemy_spawned.connect(_on_enemy_spawned)

	($HUD/GameOver/Box/Retry as Button).pressed.connect(_on_retry_pressed)


func _physics_process(delta: float) -> void:
	run_time += delta
	spawner.run_time = run_time


func _process(_delta: float) -> void:
	time_label.text = format_clock(run_time)
	debug_label.text = "\n".join([
		"[WASD] mover   [Espacio/Click] parry   [E] +enemigos",
		"Enemigos: %d    Bajas: %d    Golpes recibidos: %d" % [
			spawner.alive_count, _kills, _hits_taken],
		"Parries: %d de %d pulsos (%s acierto)" % [
			_pulses_connected, _pulses, _accuracy_text()],
		"Oleada: 1 enemigo cada %.2fs" % spawner.current_interval(),
		"Mezcla: %s" % _mix_text(),
	])


static func format_clock(seconds: float) -> String:
	var total: int = int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


func _accuracy_text() -> String:
	if _pulses == 0:
		return "-"
	return "%d%%" % roundi(100.0 * float(_pulses_connected) / float(_pulses))


## Live view of the spawn table, so it is obvious when a type unlocks and how
## fast it is ramping in.
func _mix_text() -> String:
	var parts: PackedStringArray = []
	for type: EnemyType in spawner.enemy_types:
		var weight: float = type.weight_at(run_time)
		if weight <= 0.0:
			parts.append("%s (en %s)" % [type.display_name, format_clock(type.unlock_time)])
		else:
			parts.append("%s x%d [%d]" % [type.display_name, roundi(weight), spawner.alive_of(type)])
	return "  ".join(parts)


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.hit_player.connect(player.take_damage)
	enemy.hit_player.connect(_on_player_hit)


func _on_enemy_died(_enemy: Enemy, _xp: int) -> void:
	_kills += 1


func _on_player_hit(_damage: int) -> void:
	_hits_taken += 1


## Accuracy is the fastest read on whether the window and radius are tuned
## sanely: a run that lands 95% of pulses is too forgiving.
func _on_parry_pulsed(hits: int) -> void:
	_pulses += 1
	if hits > 0:
		_pulses_connected += 1


func _on_player_died() -> void:
	($HUD/GameOver/Box/Summary as Label).text = "Sobreviviste %s" % format_clock(run_time)
	($HUD/GameOver/Box/Detail as Label).text = "%d bajas · %d parries acertados de %d pulsos" % [
		_kills, _pulses_connected, _pulses]
	game_over.visible = true
	($HUD/GameOver/Box/Retry as Button).grab_focus()
	# The panel is process_mode ALWAYS, so it keeps working while everything
	# else is frozen.
	get_tree().paused = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


## Keeps the camera from showing the void outside the arena.
func _apply_camera_limits(camera: Camera2D, bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
