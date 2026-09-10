extends Node2D

## Root of the gameplay scene. Owns the run clock and the XP/level progression,
## wires the arena bounds into the player, the camera and the spawner, and
## drives the HUD.

## XP needed for the first level-up, then how much each level adds.
const XP_BASE: int = 8
const XP_STEP: int = 6
const UPGRADE_CHOICES: int = 3

@onready var arena: Arena = $Arena
@onready var player: Player = $Player
@onready var spawner: Spawner = $Spawner
@onready var time_label: Label = $HUD/TimeLabel
@onready var level_label: Label = $HUD/LevelLabel
@onready var xp_bar: ProgressBar = $HUD/XPBar
@onready var debug_label: Label = $HUD/DebugLabel
@onready var health_pips: HealthPips = $HUD/HealthPips
@onready var game_over: Control = $HUD/GameOver
@onready var level_up: Control = $HUD/LevelUp

## Single source of truth for elapsed survival time: both the HUD and the spawn
## cadence read it, so the clock on screen always matches the pressure.
var run_time: float = 0.0

var level: int = 1
var xp: int = 0

var _kills: int = 0
var _hits_taken: int = 0
var _pulses: int = 0
var _pulses_connected: int = 0
## Level-ups earned but not yet spent. A big kill can grant several at once.
var _pending_level_ups: int = 0
var _offered: Array[Upgrades.Entry] = []
var _option_buttons: Array[Button] = []


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

	for i: int in UPGRADE_CHOICES:
		var button: Button = level_up.get_node("Box/Option%d" % i)
		button.pressed.connect(_on_upgrade_chosen.bind(i))
		_option_buttons.append(button)

	_refresh_progress_hud()


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
		"Ventana %.2fs · radio %.0f · cooldown %.2fs · daño %d/%d · i-frames %.2fs" % [
			player.parry_window, player.parry_radius, player.parry_cooldown,
			player.parry_damage, _damage_cap(), player.invuln_on_parry_kill],
		"Oleada: 1 enemigo cada %.2fs   |   %s" % [spawner.current_interval(), _mix_text()],
	])


static func format_clock(seconds: float) -> String:
	var total: int = int(seconds)
	return "%02d:%02d" % [total / 60, total % 60]


# --- Progression -----------------------------------------------------------

func xp_for_next_level() -> int:
	return XP_BASE + (level - 1) * XP_STEP


func gain_xp(amount: int) -> void:
	if amount <= 0 or player.is_dead:
		return

	xp += amount
	while xp >= xp_for_next_level():
		xp -= xp_for_next_level()
		level += 1
		_pending_level_ups += 1

	_refresh_progress_hud()

	if _pending_level_ups > 0 and not level_up.visible:
		_show_upgrade_choices()


## Derived from the live roster, so adding a tougher enemy reopens the damage
## upgrade on its own.
func _damage_cap() -> int:
	return Upgrades.damage_cap_for(spawner.enemy_types)


func _refresh_progress_hud() -> void:
	level_label.text = "Nv. %d" % level
	xp_bar.value = float(xp) / float(xp_for_next_level())


func _show_upgrade_choices() -> void:
	_offered = Upgrades.roll(player, UPGRADE_CHOICES, _damage_cap())
	if _offered.is_empty():
		# Everything is maxed out; nothing left to spend levels on. Tear the
		# panel down explicitly: reaching this from an earlier choice would
		# otherwise leave a stale panel up with the tree frozen behind it.
		_pending_level_ups = 0
		level_up.visible = false
		get_tree().paused = false
		return

	(level_up.get_node("Box/Title") as Label).text = "¡Nivel %d!" % level
	for i: int in UPGRADE_CHOICES:
		var button: Button = _option_buttons[i]
		button.visible = i < _offered.size()
		if button.visible:
			button.text = "%s   ·   %s" % [_offered[i].title, _offered[i].describe(player)]

	level_up.visible = true
	_option_buttons[0].grab_focus()
	get_tree().paused = true


func _on_upgrade_chosen(index: int) -> void:
	# Guarded because letting this run spuriously drives _pending_level_ups
	# negative, which silently swallows the next several level-ups instead of
	# failing loudly.
	if not level_up.visible or _pending_level_ups <= 0 or index >= _offered.size():
		return

	_offered[index].apply.call(player)
	_pending_level_ups -= 1
	level_up.visible = false

	if _pending_level_ups > 0:
		_show_upgrade_choices()
	else:
		get_tree().paused = false


# --- Wiring ----------------------------------------------------------------

func _on_enemy_spawned(enemy: Enemy) -> void:
	enemy.died.connect(_on_enemy_died)
	enemy.hit_player.connect(player.take_damage)
	enemy.hit_player.connect(_on_player_hit)
	enemy.projectile_fired.connect(_on_projectile_fired)


## Shots take the same damage path as melee hits, so there is one place where
## the player can be hurt and one place where hits are counted.
func _on_projectile_fired(projectile: Projectile) -> void:
	projectile.hit_player.connect(player.take_damage)
	projectile.hit_player.connect(_on_player_hit)


func _on_enemy_died(_enemy: Enemy, enemy_xp: int) -> void:
	_kills += 1
	gain_xp(enemy_xp)


func _on_player_hit(_damage: int) -> void:
	_hits_taken += 1


## Accuracy is the fastest read on whether the window and radius are tuned
## sanely: a run that lands 95% of pulses is too forgiving.
func _on_parry_pulsed(hits: int) -> void:
	_pulses += 1
	if hits > 0:
		_pulses_connected += 1


func _on_player_died() -> void:
	level_up.visible = false
	($HUD/GameOver/Box/Summary as Label).text = "Sobreviviste %s" % format_clock(run_time)
	($HUD/GameOver/Box/Detail as Label).text = "Nivel %d · %d bajas · %d parries de %d pulsos" % [
		level, _kills, _pulses_connected, _pulses]
	game_over.visible = true
	($HUD/GameOver/Box/Retry as Button).grab_focus()
	# Both panels are process_mode ALWAYS, so they keep working while everything
	# else is frozen.
	get_tree().paused = true


func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


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


## Keeps the camera from showing the void outside the arena.
func _apply_camera_limits(camera: Camera2D, bounds: Rect2) -> void:
	camera.limit_left = int(bounds.position.x)
	camera.limit_top = int(bounds.position.y)
	camera.limit_right = int(bounds.end.x)
	camera.limit_bottom = int(bounds.end.y)
