extends CanvasLayer

@onready var dimmer = $Dimmer
@onready var modal_panel = $Center/ModalPanel
@onready var title_lbl = $Center/ModalPanel/VBox/Header/EventTitle
@onready var desc_lbl = $Center/ModalPanel/VBox/Desc
@onready var buttons_vbox = $Center/ModalPanel/VBox/Buttons

var current_event_data: EventData

func setup(data: EventData) -> void:
	current_event_data = data
	
	if not is_inside_tree():
		await ready
		
	title_lbl.text = data.title
	desc_lbl.text = data.description
	
	for child in buttons_vbox.get_children():
		child.queue_free()
		
	for choice in data.choices:
		var btn = Button.new()
		btn.text = choice.label
		btn.custom_minimum_size.y = 120
		btn.pressed.connect(_on_choice_pressed.bind(choice))
		bind_button_animation(btn)
		buttons_vbox.add_child(btn)
		
	_play_intro_animation()

func _play_intro_animation() -> void:
	AudioManager.play_ui_click()
	AudioManager.vibrate("medium")
		
	dimmer.modulate.a = 0.0
	modal_panel.scale = Vector2(0.8, 0.8)
	modal_panel.modulate.a = 0.0
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(dimmer, "modulate:a", 1.0, 0.3)
	t.tween_property(modal_panel, "modulate:a", 1.0, 0.3)
	t.tween_property(modal_panel, "scale", Vector2(1.0, 1.0), 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_choice_pressed(choice: Dictionary) -> void:
	AudioManager.play_ui_click()
	
	if choice.has("cost") and choice.cost > 0:
		EconomyManager.add_money(-choice.cost)
	if choice.has("risk_change"):
		RiskManager.add_risk(choice.risk_change)
	if choice.has("rep_change"):
		ReputationManager.add_reputation(choice.rep_change)
		
	if current_event_data.id == "NETWORK SHUTDOWN":
		ProgressionManager.unlock_achievement("survivor")
	ProgressionManager.add_xp(50)
		
	var t = create_tween()
	t.set_parallel(true)
	t.tween_property(dimmer, "modulate:a", 0.0, 0.3)
	t.tween_property(modal_panel, "modulate:a", 0.0, 0.3)
	t.tween_property(modal_panel, "scale", Vector2(0.8, 0.8), 0.3).set_trans(Tween.TRANS_SINE)
	t.chain().tween_callback(queue_free)

func bind_button_animation(btn: Button) -> void:
	btn.button_down.connect(func(): 
		AudioManager.play_ui_click()
		AudioManager.vibrate("light")
		btn.pivot_offset = btn.size / 2
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.05).set_trans(Tween.TRANS_SINE)
	)
	btn.button_up.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
