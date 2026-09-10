class_name Player
extends CharacterBody2D

## Player avatar: constant-speed 8-directional movement plus the radial parry
## pulse the whole prototype is built around.

const SPEED: float = 250.0
## How long the pulse visual lingers after the window closes.
const PULSE_FADE: float = 0.22

## Emitted the instant an enemy is parried. Phase 7 hangs hit-stop and screen
## shake off this: waiting for the window to close would delay the impact by up
## to a full window, which is exactly the feedback that has to be immediate.
signal parry_hit(enemy: Enemy)
## Emitted when the window closes, carrying the pulse total. Stats, not juice.
signal parry_pulsed(hits: int)
signal health_changed(current: int, maximum: int)
signal died

@export var radius: float = 16.0
@export var body_color: Color = Color("4fc3f7")
@export var outline_color: Color = Color("e1f5fe")

@export_group("Survival")
@export var max_health: int = 3
## Grace period after a hit. Without it a single overlapping pair of enemies
## empties the health bar in one swing cycle.
@export var invulnerable_time: float = 0.9
@export var hurt_color: Color = Color("ff5252")

@export_group("Parry")
## Seconds the pulse stays live. It is re-evaluated every physics frame while
## open, so an enemy that *enters* Telegraph mid-window is still caught — that
## is what makes a wider window feel wider.
@export var parry_window: float = 0.15
@export var parry_radius: float = 120.0:
	set = _set_parry_radius
@export var parry_cooldown: float = 0.5
@export var parry_damage: int = 1
@export var parry_ready_color: Color = Color("b2ff59")
@export var parry_whiff_color: Color = Color("90a4ae")

## Arena rectangle the player is confined to. Set by Main at startup.
var movement_bounds: Rect2 = Rect2()

var health: int = 0
var is_dead: bool = false

var _facing: Vector2 = Vector2.RIGHT
var _invulnerable_left: float = 0.0
var _cooldown_left: float = 0.0
var _window_left: float = 0.0
## Age of the current pulse visual; negative means no pulse on screen.
var _pulse_age: float = -1.0
var _pulse_connected: bool = false
## Enemies already parried by the *current* pulse, so one press cannot chew
## through the same enemy on consecutive frames.
var _pulse_victims: Array[Enemy] = []

@onready var camera: Camera2D = $Camera2D
@onready var parry_area: Area2D = $ParryArea
@onready var _parry_shape: CollisionShape2D = $ParryArea/CollisionShape2D


func _ready() -> void:
	_set_parry_radius(parry_radius)
	health = max_health
	health_changed.emit(health, max_health)


func _physics_process(delta: float) -> void:
	if _invulnerable_left > 0.0:
		_invulnerable_left = maxf(0.0, _invulnerable_left - delta)
		queue_redraw()

	_update_parry(delta)
	_update_movement()


# --- Survival --------------------------------------------------------------

func is_invulnerable() -> bool:
	return _invulnerable_left > 0.0


func take_damage(amount: int) -> void:
	if is_dead or is_invulnerable():
		return

	health = maxi(0, health - amount)
	_invulnerable_left = invulnerable_time
	health_changed.emit(health, max_health)
	queue_redraw()

	if health == 0:
		is_dead = true
		died.emit()


## Used by the phase 6 upgrade that grants i-frames on a parry kill. Never
## shortens an existing window.
func grant_invulnerability(seconds: float) -> void:
	_invulnerable_left = maxf(_invulnerable_left, seconds)


# --- Movement --------------------------------------------------------------

func _update_movement() -> void:
	# get_vector() already normalises, so diagonals are not faster.
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * SPEED
	move_and_slide()

	if movement_bounds.has_area():
		global_position = _clamp_to_bounds(global_position)

	if not direction.is_zero_approx() and direction.dot(_facing) < 0.999:
		_facing = direction
		queue_redraw()


func _clamp_to_bounds(position_to_clamp: Vector2) -> Vector2:
	return Vector2(
		clampf(position_to_clamp.x, movement_bounds.position.x + radius, movement_bounds.end.x - radius),
		clampf(position_to_clamp.y, movement_bounds.position.y + radius, movement_bounds.end.y - radius)
	)


# --- Parry -----------------------------------------------------------------

func is_parry_ready() -> bool:
	return _cooldown_left <= 0.0


func _update_parry(delta: float) -> void:
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)
		queue_redraw()

	if Input.is_action_just_pressed("parry") and is_parry_ready():
		_start_pulse()

	if _window_left > 0.0:
		_window_left -= delta
		_sweep_pulse()
		if _window_left <= 0.0:
			parry_pulsed.emit(_pulse_victims.size())

	if _pulse_age >= 0.0:
		_pulse_age += delta
		queue_redraw()
		if _pulse_age > parry_window + PULSE_FADE:
			_pulse_age = -1.0


func _start_pulse() -> void:
	_window_left = parry_window
	_cooldown_left = parry_cooldown
	_pulse_age = 0.0
	_pulse_connected = false
	_pulse_victims.clear()
	_sweep_pulse()


## Runs every physics frame the window is open. The Area2D monitors
## continuously (rather than being toggled on at press time) so its overlap list
## is already current — toggling would cost a physics frame of latency, which is
## exactly the wrong place to spend one.
func _sweep_pulse() -> void:
	for body: Node2D in parry_area.get_overlapping_bodies():
		var enemy := body as Enemy
		if enemy == null or enemy in _pulse_victims:
			continue
		if not enemy.is_parry_vulnerable():
			continue

		enemy.receive_parry(parry_damage)
		_pulse_victims.append(enemy)
		_pulse_connected = true
		parry_hit.emit(enemy)


func _set_parry_radius(value: float) -> void:
	parry_radius = value
	# is_node_ready() is still false *inside* _ready(), so testing it here made
	# the initial call a no-op and let an inspector-set radius silently disagree
	# with the Area2D's actual reach. The @onready shape is the real signal.
	if _parry_shape == null:
		return
	# Duplicated so upgrades never mutate the shape shared by the scene file.
	var circle: CircleShape2D = (_parry_shape.shape as CircleShape2D).duplicate()
	circle.radius = parry_radius
	_parry_shape.shape = circle


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	if _pulse_age >= 0.0:
		_draw_pulse()

	var fill: Color = body_color if is_parry_ready() else body_color.darkened(0.55)
	var edge: Color = outline_color

	if is_invulnerable():
		# Flash between the hurt colour and the body so the grace period is
		# visible: knowing you are briefly safe changes whether you push in.
		var blink: float = 0.5 + 0.5 * sin(_invulnerable_left * 34.0)
		fill = fill.lerp(hurt_color, blink)
		edge = edge.lerp(hurt_color, blink)

	draw_circle(Vector2.ZERO, radius, fill, true, -1.0, true)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, edge, 2.0, true)
	_draw_facing_notch()
	_draw_cooldown()


## While the window is open the ring sits at the true parry radius, so the reach
## is never a guess; once it closes the ring blooms outward and fades. Green
## means it caught something, grey means it whiffed.
func _draw_pulse() -> void:
	var tint: Color = parry_ready_color if _pulse_connected else parry_whiff_color

	if _pulse_age <= parry_window:
		draw_circle(Vector2.ZERO, parry_radius, Color(tint, 0.08), true, -1.0, true)
		draw_arc(Vector2.ZERO, parry_radius, 0.0, TAU, 64, Color(tint, 0.9), 3.0, true)
		return

	var fade: float = clampf((_pulse_age - parry_window) / PULSE_FADE, 0.0, 1.0)
	draw_arc(
		Vector2.ZERO, parry_radius * lerpf(1.0, 1.18, fade), 0.0, TAU, 64,
		Color(tint, (1.0 - fade) * 0.8), lerpf(3.0, 0.5, fade), true
	)


## Ring sweeping back to full around the player. The cooldown gates the only
## offence in the game, so it has to be readable at a glance without looking
## away from the enemies: a dim track shows the whole lap, a bright arc fills
## it, and the body itself stays dulled until the parry is up again.
func _draw_cooldown() -> void:
	var ring_radius: float = radius + 9.0

	if is_parry_ready():
		draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 40, Color(parry_ready_color, 0.5), 3.0, true)
		return

	draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 40, Color(parry_ready_color, 0.12), 3.0, true)
	var progress: float = 1.0 - _cooldown_left / parry_cooldown
	draw_arc(
		Vector2.ZERO, ring_radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 40,
		Color(parry_ready_color, 0.85), 3.5, true
	)


## Small triangle marking the last movement direction. Purely a readability aid
## while there is no art; it also previews where directional feedback would go.
func _draw_facing_notch() -> void:
	var tip: Vector2 = _facing * (radius + 7.0)
	var side: Vector2 = _facing.orthogonal() * (radius * 0.45)
	var base: Vector2 = _facing * (radius * 0.6)
	draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), outline_color)
