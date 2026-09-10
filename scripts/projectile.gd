class_name Projectile
extends Area2D

## Shot fired by ranged enemies. Deliberately slower than the player so it can
## be sidestepped: the ranged type should widen the answer set (dodge it, or
## parry the shooter before it fires), not shrink it to one.

signal hit_player(damage: int)

const MAX_LIFETIME: float = 4.0

var damage: int = 1
var speed: float = 230.0
var direction: Vector2 = Vector2.RIGHT
var color: Color = Color("ec407a")
var radius: float = 7.0

var _lifetime: float = 0.0


## Called before the projectile enters the tree.
func setup(p_damage: int, p_speed: float, p_direction: Vector2, p_color: Color) -> void:
	damage = p_damage
	speed = p_speed
	direction = p_direction.normalized()
	color = p_color
	rotation = direction.angle()


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= MAX_LIFETIME:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		hit_player.emit(damage)
		queue_free()


## Drawn along local +X with the node rotated to aim, so the tail always trails
## correctly without a redraw per frame.
func _draw() -> void:
	draw_line(Vector2(-radius * 2.6, 0.0), Vector2.ZERO, Color(color, 0.35), radius * 0.9, true)
	draw_circle(Vector2.ZERO, radius, color, true, -1.0, true)
	draw_circle(Vector2.ZERO, radius * 0.45, Color(1, 1, 1, 0.9), true, -1.0, true)
