class_name EnemyType
extends Resource

## Per-type enemy tuning. One Enemy.tscn is reused for every type; only this
## resource changes. Adding a new enemy kind means adding a .tres, not a scene.

@export var display_name: String = "Fodder"

@export_group("Visuals")
## Colour while idle / chasing.
@export var color: Color = Color("ef5350")
## Colour during the telegraph. Must read as clearly different from `color`:
## this is the signal the whole parry mechanic depends on.
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
