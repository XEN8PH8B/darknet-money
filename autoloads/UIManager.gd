extends Node

var current_scene = null
var transition_rect: ColorRect

func _ready() -> void:
	var root = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)
	
	transition_rect = ColorRect.new()
	transition_rect.color = Color(0.02, 0.02, 0.02, 0.0)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	transition_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var canvas = CanvasLayer.new()
	canvas.layer = 128
	canvas.add_child(transition_rect)
	add_child(canvas)

func switch_scene(path: String) -> void:
	AudioManager.play_ui_click()
	transition_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var t = create_tween()
	t.tween_property(transition_rect, "color:a", 1.0, 0.25).set_trans(Tween.TRANS_SINE)
	t.tween_callback(func(): _load_scene(path))

func _load_scene(path: String) -> void:
	call_deferred("_deferred_switch", path)

func _deferred_switch(path: String) -> void:
	if current_scene:
		current_scene.free()
	
	var scene = load(path)
	if scene:
		current_scene = scene.instantiate()
		get_tree().root.add_child(current_scene)
		get_tree().current_scene = current_scene
		
		# Fade back in
		var t = create_tween()
		t.tween_property(transition_rect, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_SINE)
		t.tween_callback(func(): transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)

func shake_screen(intensity: float = 10.0, duration: float = 0.5) -> void:
	if current_scene == null: return
	
	var t = create_tween()
	t.set_loops(int(duration * 20))
	t.tween_callback(func():
		var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * intensity
		current_scene.position = offset
	).set_delay(0.05)
	
	var t2 = create_tween()
	t2.tween_interval(duration)
	t2.tween_callback(func(): current_scene.position = Vector2.ZERO)

func animate_money_label(label: Label, start_val: float, end_val: float, duration: float = 1.0) -> void:
	if not label.is_inside_tree(): return
	var t = label.create_tween()
	t.tween_method(func(val): label.text = "$%.2f" % val, start_val, end_val, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func spawn_money_particles(pos: Vector2) -> void:
	if current_scene == null: return
	var part_scene = load("res://scenes/particles/MoneyParticles.tscn")
	if part_scene:
		var part = part_scene.instantiate()
		part.position = pos
		current_scene.add_child(part)
