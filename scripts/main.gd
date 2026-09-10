extends Node2D

## Root of the gameplay scene. Wires the arena bounds into the player, the
## camera and the spawner, and keeps a debug readout until the real HUD lands
## in phase 4.

@onready var arena: Arena = $Arena
@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var debug_label: Label = $DebugLayer/DebugLabel

var _kills: int = 0
var _hits_taken: int = 0


func _ready() -> void:
	var bounds: Rect2 = arena.get_bounds()

	player.movement_bounds = bounds
	_apply_camera_limits(player.camera, bounds)

	spawner.target = player
	spawner.bounds = bounds
	spawner.enemy_spawned.connect(_on_enemy_spawned)


func _process(_delta: float) -> void:
	debug_label.text = "\n".join([
		"[E] generar enemigos    [WASD] mover",
		"Enemigos: %d" % spawner.get_child_count(),
		"Golpes recibidos: %d" % _hits_taken,
		"Bajas: %d" % _kills,
	])


func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.hit_player.connect(_on_player_hit)


func _on_enemy_died(_enemy: Enemy, _xp: int) -> void:
	_kills += 1


## Player health arrives in phase 5; for now the hit is only counted so the
## Attack state can be verified without a debugger.
func _on_player_hit(_damage: int) -> void:
	_hits_taken += 1


## Keeps the camera from showing the void outside the arena.
func _apply_camera_limits(camera: Camera2D, bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
