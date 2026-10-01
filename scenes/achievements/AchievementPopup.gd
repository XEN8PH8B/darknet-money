extends CanvasLayer

@onready var dimmer = $Dimmer
@onready var panel = $Center/Panel
@onready var title_lbl = $Center/Panel/Margin/VBox/Title
@onready var desc_lbl = $Center/Panel/Margin/VBox/Desc

func setup(title: String, desc: String) -> void:
	if not is_inside_tree():
		await ready
		
	title_lbl.text = "ACHIEVEMENT UNLOCKED:\n" + title
	desc_lbl.text = desc
	
	AudioManager.play_ui_click()
	AudioManager.vibrate("medium")
		
	dimmer.modulate.a = 0.0
	panel.scale = Vector2(0.5, 0.5)
	panel.modulate.a = 0.0
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(dimmer, "modulate:a", 1.0, 0.3)
	t.tween_property(panel, "modulate:a", 1.0, 0.3)
	t.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	var t_close = create_tween()
	t_close.tween_interval(3.5)
	t_close.tween_callback(_close)

func _close() -> void:
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(dimmer, "modulate:a", 0.0, 0.3)
	t.tween_property(panel, "modulate:a", 0.0, 0.3)
	t.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_SINE)
	t.chain().tween_callback(queue_free)
