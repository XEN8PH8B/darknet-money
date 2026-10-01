extends Node

var synth_player: AudioStreamPlayer
var click_player: AudioStreamPlayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ambient procedural drone
	synth_player = AudioStreamPlayer.new()
	add_child(synth_player)
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = 44100
	generator.buffer_length = 0.5
	synth_player.stream = generator
	synth_player.volume_db = -20.0
	synth_player.play()
	
	# Standard click player
	click_player = AudioStreamPlayer.new()
	add_child(click_player)

func _process(_delta: float) -> void:
	if synth_player.playing and synth_player.stream is AudioStreamGenerator:
		_fill_ambient_buffer()

var phase = 0.0
func _fill_ambient_buffer() -> void:
	var playback = synth_player.get_stream_playback()
	if playback == null: return
	
	var frames_available = playback.get_frames_available()
	if frames_available == 0: return
	
	var increment = (45.0 / 44100.0) * TAU # 45 Hz deep sub drone
	
	for i in range(frames_available):
		var val = sin(phase) * 0.5
		# Add subtle noise for texture
		val += (randf() * 0.1 - 0.05)
		playback.push_frame(Vector2(val, val))
		phase += increment
	if phase >= TAU:
		phase -= TAU

func play_ui_click() -> void:
	# A quick procedural tick
	var gen = AudioStreamGenerator.new()
	gen.mix_rate = 44100
	gen.buffer_length = 0.1
	click_player.stream = gen
	click_player.volume_db = -10.0
	click_player.play()
	
	var pb = click_player.get_stream_playback()
	if pb:
		var frames = pb.get_frames_available()
		for i in range(frames):
			# High frequency click, decaying fast
			var decay = 1.0 - (float(i) / frames)
			var val = (randf() * 2.0 - 1.0) * decay * 0.5
			pb.push_frame(Vector2(val, val))

func vibrate(style: String = "light") -> void:
	if OS.get_name() != "iOS" and OS.get_name() != "Android":
		return
		
	if style == "light":
		Input.vibrate_handheld(15)
	elif style == "medium":
		Input.vibrate_handheld(30)
	elif style == "heavy":
		Input.vibrate_handheld(60)
	elif style == "error":
		Input.vibrate_handheld(100)
