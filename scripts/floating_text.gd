class_name FloatingText
extends Label

## Damage/kill readout that rises off an enemy and fades. Parented to the world
## rather than to the enemy, so it survives the enemy being freed.

const RISE: float = 34.0
const LIFETIME: float = 0.55


func setup(value: String, color: Color, font_size: int) -> void:
	text = value
	add_theme_color_override(&"font_color", color)
	add_theme_font_size_override(&"font_size", font_size)
	add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.8))
	add_theme_constant_override(&"outline_size", 5)


func _ready() -> void:
	# Centre on the spawn point now that the label has measured itself.
	position -= size * 0.5

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - RISE, LIFETIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, LIFETIME) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
