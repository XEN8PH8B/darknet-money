extends Control

@onready var back_btn = $SafeAreaMargin/VBox/Header/BackBtn
@onready var money_label = $SafeAreaMargin/VBox/Header/MoneyLabel
@onready var active_list = $SafeAreaMargin/VBox/Scroll/ListVBox/ActiveSection/ActiveList
@onready var available_list = $SafeAreaMargin/VBox/Scroll/ListVBox/AvailableSection/AvailableList

var active_ui_elements: Dictionary = {}

func _ready() -> void:
	back_btn.pressed.connect(func(): UIManager.switch_scene("res://scenes/main/Main.tscn"))
	
	WorkManager.operations_updated.connect(_on_ops_updated)
	WorkManager.operation_started.connect(func(_id): _on_ops_updated())
	WorkManager.operation_completed.connect(func(id, _profit): _on_op_completed(id))
	EconomyManager.money_changed.connect(_on_money_changed)
	
	_on_money_changed(EconomyManager.get_money())
	_update_texts()
	
	_build_available_list()
	_on_ops_updated()

func _update_texts() -> void:
	back_btn.text = LocalizationManager.t("BACK")
	$SafeAreaMargin/VBox/Header/Title.text = LocalizationManager.t("WORK_TITLE")
	$SafeAreaMargin/VBox/Scroll/ListVBox/ActiveSection/Title.text = LocalizationManager.t("ACTIVE_OPERATIONS")
	$SafeAreaMargin/VBox/Scroll/ListVBox/AvailableSection/Title.text = LocalizationManager.t("AVAILABLE_TARGETS")

func _process(_delta: float) -> void:
	_update_active_timers()

func _on_money_changed(amount: float) -> void:
	money_label.text = "$%.2f" % amount

func _build_available_list() -> void:
	for child in available_list.get_children():
		child.queue_free()
		
	for op_id in WorkManager.available_operations.keys():
		var op_data = WorkManager.available_operations[op_id]
		var card = _create_available_card(op_data)
		available_list.add_child(card)

func _on_ops_updated() -> void:
	var current_actives = WorkManager.get_active_operations()
	
	var seen_ids = []
	for op in current_actives:
		seen_ids.append(op.instance_id)
		if not active_ui_elements.has(op.instance_id):
			var card = _create_active_card(op)
			active_list.add_child(card)
		else:
			_update_active_card_state(op)
			
	var to_remove = []
	for inst_id in active_ui_elements.keys():
		if not seen_ids.has(inst_id):
			to_remove.append(inst_id)
			
	for inst_id in to_remove:
		_on_op_completed(inst_id)

func _update_active_timers() -> void:
	var current_time = Time.get_unix_time_from_system()
	for op in WorkManager.get_active_operations():
		if active_ui_elements.has(op.instance_id):
			var ui = active_ui_elements[op.instance_id]
			if op.state == "running":
				var op_data = WorkManager.available_operations[op.op_id]
				var elapsed = current_time - op.start_time
				var left = int(max(0, op_data.duration - elapsed))
				ui.time_label.text = "%02d:%02d" % [left / 60, left % 60]
			elif op.state == "paused_by_event":
				ui.time_label.text = LocalizationManager.t("PAUSED")

func _create_available_card(op_data: OperationData) -> PanelContainer:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.add_theme_constant_override("separation", 12)
	
	var title = Label.new()
	title.text = LocalizationManager.t(op_data.id.to_upper())
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = LocalizationManager.t(op_data.id.to_upper() + "_DESC")
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	vbox.add_child(desc)
	
	var stats = Label.new()
	stats.text = LocalizationManager.t("COST") + ": $%d  |  " % op_data.cost + LocalizationManager.t("INCOME") + ": $%d-$%d  |  " % [op_data.min_reward, op_data.max_reward] + LocalizationManager.t("RISK") + ": %d%%" % int(op_data.risk * 100)
	stats.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(stats)
	
	var btn = Button.new()
	btn.text = LocalizationManager.t("START_OPERATION")
	btn.pressed.connect(func(): _on_start_pressed(op_data.id))
	vbox.add_child(btn)
	
	bind_button_animation(btn)
	return panel

func _create_active_card(op: Dictionary) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.modulate.a = 0.0
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	vbox.add_theme_constant_override("separation", 12)
	
	var op_data = WorkManager.available_operations[op.op_id]
	
	var title = Label.new()
	title.text = LocalizationManager.t(op_data.id.to_upper()) + " (" + LocalizationManager.t("ACTIVE") + ")"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.1, 0.8, 0.4))
	vbox.add_child(title)
	
	var hbox = HBoxContainer.new()
	vbox.add_child(hbox)
	
	var time_lbl = Label.new()
	time_lbl.text = "00:00"
	time_lbl.add_theme_font_size_override("font_size", 48)
	time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(time_lbl)
	
	var income_lbl = Label.new()
	income_lbl.text = LocalizationManager.t("PROJ") + ": $%.2f" % op.projected_income
	income_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	income_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(income_lbl)
	
	var event_panel = PanelContainer.new()
	event_panel.visible = false
	var ev_vbox = VBoxContainer.new()
	event_panel.add_child(ev_vbox)
	var ev_title = Label.new()
	ev_title.text = LocalizationManager.t("EVENT")
	ev_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))
	ev_vbox.add_child(ev_title)
	
	var btn_hbox = HBoxContainer.new()
	var resolve_btn1 = Button.new()
	resolve_btn1.text = LocalizationManager.t("PAY_FEE") + " ($500)"
	resolve_btn1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolve_btn1.pressed.connect(func(): WorkManager.resolve_event(op.instance_id, "pay_fee"))
	bind_button_animation(resolve_btn1)
	
	var resolve_btn2 = Button.new()
	resolve_btn2.text = LocalizationManager.t("TAKE_RISK")
	resolve_btn2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resolve_btn2.pressed.connect(func(): WorkManager.resolve_event(op.instance_id, "take_risk"))
	bind_button_animation(resolve_btn2)
	
	btn_hbox.add_child(resolve_btn1)
	btn_hbox.add_child(resolve_btn2)
	ev_vbox.add_child(btn_hbox)
	
	vbox.add_child(event_panel)
	
	active_ui_elements[op.instance_id] = {
		"panel": panel,
		"time_label": time_lbl,
		"event_panel": event_panel,
		"ev_title": ev_title
	}
	
	var t = create_tween()
	t.tween_property(panel, "modulate:a", 1.0, 0.5)
	
	_update_active_card_state(op)
	return panel

func _update_active_card_state(op: Dictionary) -> void:
	var ui = active_ui_elements[op.instance_id]
	if op.state == "paused_by_event":
		ui.event_panel.visible = true
		ui.ev_title.text = LocalizationManager.t("EVENT") + ": " + LocalizationManager.t(op.active_event)
	else:
		ui.event_panel.visible = false

func _on_start_pressed(op_id: String) -> void:
	AudioManager.play_ui_click()
	var success = WorkManager.start_operation(op_id)
	if not success:
		NotificationManager.notify("ERROR", "Not enough funds.", "error")

func _on_op_completed(inst_id: String) -> void:
	if active_ui_elements.has(inst_id):
		var ui = active_ui_elements[inst_id]
		active_ui_elements.erase(inst_id)
		var t = create_tween()
		t.tween_property(ui.panel, "modulate:a", 0.0, 0.5)
		t.tween_callback(ui.panel.queue_free)

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
