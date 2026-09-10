class_name Sfx
extends Node

## Placeholder audio, synthesised at startup rather than shipped as files. The
## prototype has no real assets and no artist attached; generating a few short
## decaying tones keeps impact audible without adding binaries to the repo, and
## every one of these should be replaced before this is played by anyone.

const RATE: int = 22050
## Round-robin voices so a burst of parries layers instead of cutting itself off.
const VOICES: int = 8

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _players: Array[AudioStreamPlayer] = []
var _next_voice: int = 0


func _ready() -> void:
	# ALWAYS so impact audio still lands during hit-stop and the pause frames
	# around a level-up.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_streams[&"parry_swing"] = _synth(0.09, 400.0, 170.0, 3.0, 0.65, 0.16)
	_streams[&"parry_hit"] = _synth(0.15, 940.0, 210.0, 4.5, 0.22, 0.5)
	_streams[&"parry_kill"] = _synth(0.22, 1150.0, 180.0, 3.2, 0.18, 0.55)
	_streams[&"player_hurt"] = _synth(0.30, 230.0, 55.0, 2.6, 0.32, 0.5)
	_streams[&"level_up"] = _synth(0.34, 430.0, 960.0, 1.4, 0.0, 0.32)
	_streams[&"game_over"] = _synth(0.75, 300.0, 70.0, 1.2, 0.08, 0.4)

	for i: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)


func play(id: StringName, pitch_variation: float = 0.0) -> void:
	var stream: AudioStreamWAV = _streams.get(id)
	if stream == null:
		return

	var player: AudioStreamPlayer = _players[_next_voice]
	_next_voice = (_next_voice + 1) % VOICES
	player.stream = stream
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.play()


## A decaying tone that slides from one frequency to another, optionally mixed
## with noise. Enough to tell a hit from a whiff; nothing more.
static func _synth(
	duration: float, freq_start: float, freq_end: float,
	decay: float, noise: float, volume: float
) -> AudioStreamWAV:
	var sample_count: int = int(RATE * duration)
	var data: PackedByteArray = PackedByteArray()
	data.resize(sample_count * 2)

	var phase: float = 0.0
	for i: int in sample_count:
		var progress: float = float(i) / float(sample_count)
		phase += TAU * lerpf(freq_start, freq_end, progress) / float(RATE)
		var envelope: float = pow(1.0 - progress, decay)
		var value: float = lerpf(sin(phase), randf_range(-1.0, 1.0), noise)
		data.encode_s16(i * 2, int(clampf(value * envelope * volume, -1.0, 1.0) * 32767.0))

	var stream: AudioStreamWAV = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
