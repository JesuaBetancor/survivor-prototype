extends Node2D

## Root of the gameplay scene. Wires the arena bounds into the player, the
## camera and the spawner, and keeps a debug readout until the real HUD lands
## in phase 4.

@onready var arena: Arena = $Arena
@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var debug_label: Label = $DebugLayer/DebugLabel

var _alive: int = 0
var _kills: int = 0
var _hits_taken: int = 0
var _pulses: int = 0
var _pulses_connected: int = 0


func _ready() -> void:
	var bounds: Rect2 = arena.get_bounds()

	player.movement_bounds = bounds
	player.parry_pulsed.connect(_on_parry_pulsed)
	_apply_camera_limits(player.camera, bounds)

	spawner.target = player
	spawner.bounds = bounds
	spawner.enemy_spawned.connect(_on_enemy_spawned)


func _process(_delta: float) -> void:
	var accuracy: String = "-"
	if _pulses > 0:
		accuracy = "%d%%" % roundi(100.0 * float(_pulses_connected) / float(_pulses))

	debug_label.text = "\n".join([
		"[E] enemigos   [WASD] mover   [Espacio/Click] parry",
		"Enemigos: %d    Bajas: %d    Golpes recibidos: %d" % [_alive, _kills, _hits_taken],
		"Parries: %d de %d pulsos (%s acierto)" % [_pulses_connected, _pulses, accuracy],
		"Ventana %.2fs · radio %.0f · cooldown %.2fs" % [
			player.parry_window, player.parry_radius, player.parry_cooldown],
	])


func _on_enemy_spawned(enemy: Enemy) -> void:
	_alive += 1
	enemy.died.connect(_on_enemy_died)
	enemy.hit_player.connect(_on_player_hit)


func _on_enemy_died(_enemy: Enemy, _xp: int) -> void:
	_alive -= 1
	_kills += 1


## Player health arrives in phase 5; for now the hit is only counted so the
## Attack state can be verified without a debugger.
func _on_player_hit(_damage: int) -> void:
	_hits_taken += 1


## Accuracy is the fastest read on whether the window and radius are tuned
## sanely: a run that lands 95% of pulses is too forgiving.
func _on_parry_pulsed(hits: int) -> void:
	_pulses += 1
	if hits > 0:
		_pulses_connected += 1


## Keeps the camera from showing the void outside the arena.
func _apply_camera_limits(camera: Camera2D, bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
