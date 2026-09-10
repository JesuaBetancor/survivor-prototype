class_name HitStop
extends Node

## Freezes the whole game for a couple of frames on impact. The pause is short
## enough to read as weight rather than as a stutter, and it is the cheapest way
## to make a parry feel like it connected with something solid.

## Overlapping freezes, so five enemies parried on one frame do not restore the
## time scale five times, and the last one to finish is the one that unfreezes.
var _pending: int = 0


func freeze(duration: float) -> void:
	if duration <= 0.0:
		return

	_pending += 1
	Engine.time_scale = 0.0

	# process_always so it survives a paused tree, ignore_time_scale so it still
	# ticks with the time scale at zero. Without that last flag the timer never
	# fires and the game stays frozen forever.
	await get_tree().create_timer(duration, true, false, true).timeout

	_pending -= 1
	if _pending <= 0:
		_pending = 0
		Engine.time_scale = 1.0


## Engine.time_scale is global and outlives a scene reload, so anything that
## tears the run down calls this rather than trusting the timers to land.
func release() -> void:
	_pending = 0
	Engine.time_scale = 1.0
