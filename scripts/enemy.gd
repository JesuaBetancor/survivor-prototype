class_name Enemy
extends CharacterBody2D

## Enemy with an explicit Idle -> Telegraph -> Attack -> Recovery -> Idle state
## machine. The FSM is an enum plus a match, not a tree of state nodes: at the
## enemy counts a survivor-like reaches, per-node state objects would cost more
## than they clarify.

enum State { IDLE, TELEGRAPH, ATTACK, RECOVERY }

signal died(enemy: Enemy, xp: int)
signal hit_player(damage: int)

@export var type: EnemyType

## Node this enemy chases. Assigned by the spawner before it enters the tree.
var target: Node2D

var state: State = State.IDLE
## Parry hits absorbed so far. Fodder dies at 1; tougher types need more.
var parry_hits_taken: int = 0

var _state_time: float = 0.0
var _dying: bool = false
## 1.0 right after a non-lethal parry, tweened back to 0.
var _hurt_flash: float = 0.0


func _ready() -> void:
	assert(type != null, "Enemy needs an EnemyType resource before entering the tree.")
	_apply_collision_radius()
	_enter_state(State.IDLE)


func _physics_process(delta: float) -> void:
	if _dying:
		return

	_state_time += delta

	match state:
		State.IDLE:
			_tick_idle()
		State.TELEGRAPH:
			_tick_telegraph()
		State.ATTACK:
			_tick_attack()
		State.RECOVERY:
			_tick_recovery()

	move_and_slide()


# --- State machine ---------------------------------------------------------

func _enter_state(next: State) -> void:
	state = next
	_state_time = 0.0

	match state:
		State.ATTACK:
			_resolve_attack()
		State.TELEGRAPH, State.RECOVERY:
			velocity = Vector2.ZERO

	queue_redraw()


func _tick_idle() -> void:
	if not is_instance_valid(target):
		velocity = Vector2.ZERO
		return

	velocity = global_position.direction_to(target.global_position) * type.speed

	if global_position.distance_to(target.global_position) <= type.attack_range:
		# Unparriable types skip the telegraph entirely: there is no window to
		# punish, so the only counterplay is moving out of range.
		_enter_state(State.TELEGRAPH if type.is_parriable else State.ATTACK)


func _tick_telegraph() -> void:
	velocity = Vector2.ZERO
	queue_redraw()  # the shrinking wind-up ring animates every frame
	if _state_time >= type.telegraph_duration:
		_enter_state(State.ATTACK)


func _tick_attack() -> void:
	velocity = Vector2.ZERO
	if _state_time >= type.attack_duration:
		_enter_state(State.RECOVERY)


func _tick_recovery() -> void:
	velocity = Vector2.ZERO
	if _state_time >= type.recovery_duration:
		_enter_state(State.IDLE)


## Fired once, on entering Attack. The player only gets hit if they are still in
## range when the swing lands, so backing off is a valid answer to a telegraph.
func _resolve_attack() -> void:
	if not is_instance_valid(target):
		return
	if global_position.distance_to(target.global_position) <= type.attack_range:
		hit_player.emit(type.damage)


# --- Parry interface (driven by the player's pulse in phase 3) --------------

func is_parry_vulnerable() -> bool:
	return state == State.TELEGRAPH


func receive_parry(damage: int) -> void:
	if _dying or not is_parry_vulnerable():
		return

	parry_hits_taken += damage
	if parry_hits_taken >= type.parry_hits_required:
		kill()
	else:
		# Survived the parry: knocked back into recovery instead of attacking, so
		# tougher types cost several telegraph cycles rather than one combo.
		_play_survived_effect()
		_enter_state(State.RECOVERY)


func kill() -> void:
	if _dying:
		return
	_dying = true
	velocity = Vector2.ZERO
	died.emit(self, type.xp_value)
	_play_death_effect()


## White flash that swells and fades out. Placeholder juice, but the parry has
## to *read* as landed from the first playable build, not only in the debugger.
func _play_death_effect() -> void:
	set_physics_process(false)
	(get_node("CollisionShape2D") as CollisionShape2D).set_deferred("disabled", true)
	queue_redraw()

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * 1.7, 0.18) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)


## Flash for a parry that landed but did not kill, so multi-hit types still give
## the player confirmation that the timing was right.
func _play_survived_effect() -> void:
	var tween: Tween = create_tween()
	tween.tween_method(_set_hurt_flash, 1.0, 0.0, 0.25)


func _set_hurt_flash(value: float) -> void:
	_hurt_flash = value
	queue_redraw()


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	draw_circle(Vector2.ZERO, _current_radius(), _current_color(), true, -1.0, true)

	if state == State.TELEGRAPH:
		_draw_telegraph_ring()


## A ring that closes in on the enemy over the telegraph. Its radius is the
## remaining time, so the player can read *when* to parry, not just *that* an
## attack is coming.
func _draw_telegraph_ring() -> void:
	var progress: float = clampf(_state_time / type.telegraph_duration, 0.0, 1.0)
	var ring_radius: float = lerpf(type.radius * 3.2, type.radius, progress)
	var alpha: float = lerpf(0.35, 1.0, progress)
	draw_arc(
		Vector2.ZERO, ring_radius, 0.0, TAU, 40,
		Color(type.telegraph_color, alpha), 2.5, true
	)


func _current_color() -> Color:
	if _dying:
		return Color.WHITE

	if _hurt_flash > 0.0:
		return _state_color().lerp(Color.WHITE, _hurt_flash)

	return _state_color()


func _state_color() -> Color:
	match state:
		State.TELEGRAPH:
			# Ramp towards the telegraph colour so the wind-up reads even when
			# the ring is hidden behind a crowd of other enemies.
			var progress: float = clampf(_state_time / type.telegraph_duration, 0.0, 1.0)
			return type.color.lerp(type.telegraph_color, lerpf(0.5, 1.0, progress))
		State.ATTACK:
			return type.attack_color
		State.RECOVERY:
			return type.color.darkened(0.45)
		_:
			return type.color


func _current_radius() -> float:
	if state == State.TELEGRAPH:
		var progress: float = clampf(_state_time / type.telegraph_duration, 0.0, 1.0)
		return type.radius * lerpf(1.0, 1.25, progress)
	if state == State.ATTACK:
		return type.radius * 1.4
	return type.radius


func _apply_collision_radius() -> void:
	var shape: CollisionShape2D = $CollisionShape2D
	var circle: CircleShape2D = shape.shape as CircleShape2D
	# Duplicated so per-type radii do not mutate the shared scene resource.
	circle = circle.duplicate()
	circle.radius = type.radius
	shape.shape = circle
