class_name EnemyType
extends Resource

## Per-type enemy tuning. One Enemy.tscn is reused for every type; only this
## resource changes. Adding a new enemy kind means adding a .tres, not a scene.

## Silhouette. Shape carries the counterplay at a glance, before colour
## registers: solid circles are parriable melee, triangles can never be parried
## and must be dodged, rings shoot from outside your pulse. Hue alone was not
## enough once four types shared a crowded screen.
enum Shape { CIRCLE, TRIANGLE, RING }

@export var display_name: String = "Fodder"

@export_group("Visuals")
@export var shape: Shape = Shape.CIRCLE
## Colour while idle / chasing.
@export var color: Color = Color("ef5350")
## Colour during the telegraph. Kept in the same yellow family across every
## parriable type so "yellow means parry now" is one lesson, not three.
@export var telegraph_color: Color = Color("ffee58")
@export var attack_color: Color = Color("ffffff")
@export var radius: float = 14.0

@export_group("Movement")
@export var speed: float = 90.0
## Distance at which the enemy commits to an attack.
@export var attack_range: float = 46.0

@export_group("State machine")
## Seconds spent telegraphing. This is the parry window from the player's side:
## longer means more forgiving.
@export var telegraph_duration: float = 0.8
@export var attack_duration: float = 0.15
@export var recovery_duration: float = 0.6

@export_group("Combat")
@export var damage: int = 1
## Parry hits needed to kill. Fodder is 1; tougher types raise it.
@export var parry_hits_required: int = 1
## When false the enemy never enters Telegraph, so it can never be parried and
## must be dodged instead.
@export var is_parriable: bool = true
@export var xp_value: int = 1

@export_group("Ranged")
## When set, Attack fires one of these instead of resolving as a melee hit, and
## attack_range becomes firing range.
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 230.0

@export_group("Spawning")
## Run time in seconds before this type starts appearing at all.
@export var unlock_time: float = 0.0
## Relative share of spawns once fully ramped in.
@export var spawn_weight: float = 100.0
## Seconds after unlock_time for the weight to climb from 0 to spawn_weight, so
## a new type trickles in rather than replacing the mix overnight.
@export var weight_ramp_seconds: float = 0.0
## Cap on how many of this type may be alive at once. 0 means no cap. Types
## that cannot be killed need one, or they only ever accumulate.
@export var max_concurrent: int = 0


## Share of the spawn mix at a given run time.
func weight_at(run_time: float) -> float:
	if run_time < unlock_time:
		return 0.0
	if weight_ramp_seconds <= 0.0:
		return spawn_weight
	var progress: float = clampf((run_time - unlock_time) / weight_ramp_seconds, 0.0, 1.0)
	return spawn_weight * progress
