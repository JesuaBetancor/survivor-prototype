class_name GameCamera
extends Camera2D

## Follow camera with a decaying positional shake.

var _amount: float = 0.0
var _decay: float = 26.0


## Never shortens a bigger shake already in progress: several parries landing
## together should read as one heavier impact, not reset each other.
func shake(amount: float, decay: float = 26.0) -> void:
	_amount = maxf(_amount, amount)
	_decay = decay


func _process(delta: float) -> void:
	if _amount <= 0.05:
		if _amount != 0.0:
			_amount = 0.0
			offset = Vector2.ZERO
		return

	_amount = move_toward(_amount, 0.0, _decay * delta)
	offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _amount
