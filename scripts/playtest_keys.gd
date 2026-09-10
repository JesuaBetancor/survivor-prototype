class_name PlaytestKeys
extends Node

## Global playtest shortcuts. On its own ALWAYS-processing node so they still
## work from the paused defeat and level-up screens, where Main is frozen.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit_game"):
		get_tree().quit()
		return

	if event.is_action_pressed("restart"):
		# Same teardown as the Reintentar button: time_scale is global and would
		# otherwise carry a hit-stop freeze into the next run.
		Engine.time_scale = 1.0
		get_tree().paused = false
		get_tree().reload_current_scene()
