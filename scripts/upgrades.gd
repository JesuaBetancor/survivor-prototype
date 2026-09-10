class_name Upgrades
extends RefCounted

## The parry upgrade pool. Every entry sharpens the parry itself rather than
## adding a second way to deal damage: the run should get better at the one
## mechanic, not grow past it.

const WINDOW_STEP: float = 0.05
const WINDOW_CAP: float = 0.45
const RADIUS_STEP: float = 30.0
const RADIUS_CAP: float = 320.0
const COOLDOWN_FACTOR: float = 0.82
const COOLDOWN_FLOOR: float = 0.15
const IFRAME_STEP: float = 0.3
const IFRAME_CAP: float = 1.2


## One below the toughest parriable enemy in the roster, so the hardest thing on
## the field always costs at least two parries. Derived rather than fixed: add a
## 5-hit enemy and the upgrade reopens up to 4, which one-shots the 3-hit type
## while still costing two hits on the new one.
static func damage_cap_for(types: Array[EnemyType]) -> int:
	var toughest: int = 1
	for type: EnemyType in types:
		if type.is_parriable:
			toughest = maxi(toughest, type.parry_hits_required)
	return maxi(1, toughest - 1)


## One offerable upgrade. `detail` renders the before/after so the player can
## see what a pick is actually worth instead of guessing from the title.
class Entry extends RefCounted:
	var id: StringName
	var title: String
	var detail: Callable
	var apply: Callable
	var available: Callable

	func _init(
		p_id: StringName, p_title: String,
		p_detail: Callable, p_apply: Callable, p_available: Callable
	) -> void:
		id = p_id
		title = p_title
		detail = p_detail
		apply = p_apply
		available = p_available

	func describe(player: Player) -> String:
		return detail.call(player)

	func is_available(player: Player) -> bool:
		return available.call(player)


static func pool(damage_cap: int) -> Array[Entry]:
	var entries: Array[Entry] = []

	entries.append(Entry.new(
		&"window", "Ventana más amplia",
		func(p: Player) -> String:
			return "%.2fs → %.2fs" % [p.parry_window, minf(p.parry_window + WINDOW_STEP, WINDOW_CAP)],
		func(p: Player) -> void:
			p.parry_window = minf(p.parry_window + WINDOW_STEP, WINDOW_CAP),
		func(p: Player) -> bool:
			return p.parry_window < WINDOW_CAP - 0.001
	))

	entries.append(Entry.new(
		&"radius", "Pulso más grande",
		func(p: Player) -> String:
			return "%.0f → %.0f px" % [p.parry_radius, minf(p.parry_radius + RADIUS_STEP, RADIUS_CAP)],
		func(p: Player) -> void:
			p.parry_radius = minf(p.parry_radius + RADIUS_STEP, RADIUS_CAP),
		func(p: Player) -> bool:
			return p.parry_radius < RADIUS_CAP - 0.001
	))

	entries.append(Entry.new(
		&"cooldown", "Recarga más rápida",
		func(p: Player) -> String:
			return "%.2fs → %.2fs" % [
				p.parry_cooldown, maxf(p.parry_cooldown * COOLDOWN_FACTOR, COOLDOWN_FLOOR)],
		func(p: Player) -> void:
			p.parry_cooldown = maxf(p.parry_cooldown * COOLDOWN_FACTOR, COOLDOWN_FLOOR),
		func(p: Player) -> bool:
			return p.parry_cooldown > COOLDOWN_FLOOR + 0.001
	))

	entries.append(Entry.new(
		&"iframes", "Invulnerable al matar",
		func(p: Player) -> String:
			if p.invuln_on_parry_kill <= 0.0:
				return "nuevo: %.2fs tras cada muerte por parry" % IFRAME_STEP
			return "%.2fs → %.2fs" % [
				p.invuln_on_parry_kill, minf(p.invuln_on_parry_kill + IFRAME_STEP, IFRAME_CAP)],
		func(p: Player) -> void:
			p.invuln_on_parry_kill = minf(p.invuln_on_parry_kill + IFRAME_STEP, IFRAME_CAP),
		func(p: Player) -> bool:
			return p.invuln_on_parry_kill < IFRAME_CAP - 0.001
	))

	entries.append(Entry.new(
		&"damage", "Parry más fuerte",
		func(p: Player) -> String:
			return "%d → %d de daño (los resistentes caen antes)" % [
				p.parry_damage, mini(p.parry_damage + 1, damage_cap)],
		func(p: Player) -> void:
			p.parry_damage = mini(p.parry_damage + 1, damage_cap),
		func(p: Player) -> bool:
			return p.parry_damage < damage_cap
	))

	return entries


## Up to `count` distinct upgrades the player can still benefit from. Returns
## fewer only when the pool itself is exhausted.
static func roll(player: Player, count: int, damage_cap: int) -> Array[Entry]:
	var candidates: Array[Entry] = []
	for entry: Entry in pool(damage_cap):
		if entry.is_available(player):
			candidates.append(entry)

	candidates.shuffle()
	return candidates.slice(0, count)
