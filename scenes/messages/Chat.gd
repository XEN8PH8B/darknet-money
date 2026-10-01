extends Control

@onready var back_btn = $SafeAreaMargin/VBox/Header/BackBtn
@onready var avatar_rect = $SafeAreaMargin/VBox/Header/AvatarRect
@onready var name_lbl = $SafeAreaMargin/VBox/Header/VBox/NameLbl
@onready var status_lbl = $SafeAreaMargin/VBox/Header/VBox/StatusLbl
@onready var msg_list = $SafeAreaMargin/VBox/Scroll/MessageList
@onready var scroll = $SafeAreaMargin/VBox/Scroll
@onready var choices_box = $SafeAreaMargin/VBox/ChoicesBox

var current_npc: NPCData

func _ready() -> void:
	back_btn.pressed.connect(func(): UIManager.switch_scene("res://scenes/messages/Messages.tscn"))
	
	var npc_id = GameManager.current_chat_npc_id
	if npc_id.is_empty():
		npc_id = "broker"
		
	current_npc = NPCManager.get_npc(npc_id)
	if current_npc:
		name_lbl.text = LocalizationManager.t(current_npc.name.to_upper().replace(" ", "_"))
		avatar_rect.texture = current_npc.avatar
		
	back_btn.text = LocalizationManager.t("BACK")
	status_lbl.text = LocalizationManager.t("ONLINE")
		
	MessageManager.mark_chat_read(npc_id)
	MessageManager.message_received.connect(_on_msg_received)
	
	_build_messages()
	_update_choices()
	
	# Scroll to bottom on next frame
	call_deferred("_scroll_to_bottom")

func _on_msg_received(npc_id: String, text: String) -> void:
	if npc_id == current_npc.id:
		MessageManager.mark_chat_read(npc_id)
		_show_typing_then_message(text)

func _build_messages() -> void:
	for child in msg_list.get_children():
		child.queue_free()
		
	var chat = MessageManager.get_chat(current_npc.id)
	for m in chat:
		_add_message_bubble(m.text, m.sender == "player", m.timestamp, false)

func _add_message_bubble(text: String, is_player: bool, timestamp: String, animate: bool = true) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	if is_player:
		hbox.alignment = BoxContainer.ALIGNMENT_END
	else:
		hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
		
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 16
	sb.corner_radius_top_right = 16
	sb.corner_radius_bottom_left = 16 if is_player else 0
	sb.corner_radius_bottom_right = 0 if is_player else 16
	sb.bg_color = Color(0.1, 0.3, 0.5) if is_player else Color(0.15, 0.15, 0.18)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	var lbl = Label.new()
	lbl.text = LocalizationManager.t(text)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.custom_minimum_size.x = 200
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(lbl)
	
	var time_lbl = Label.new()
	time_lbl.text = timestamp
	time_lbl.add_theme_font_size_override("font_size", 14)
	time_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.7))
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(time_lbl)
	
	hbox.add_child(panel)
	msg_list.add_child(hbox)
	
	if animate:
		AudioManager.play_ui_click()
		AudioManager.vibrate("light")
		panel.scale = Vector2(0.5, 0.5)
		panel.modulate.a = 0.0
		panel.pivot_offset = Vector2(0, 0) if not is_player else Vector2(panel.size.x, 0)
		var t = create_tween()
		t.set_parallel(true)
		t.tween_property(panel, "modulate:a", 1.0, 0.2)
		t.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		call_deferred("_scroll_to_bottom")

func _show_typing_then_message(text: String) -> void:
	status_lbl.text = LocalizationManager.t("TYPING")
	status_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	
	await get_tree().create_timer(1.5).timeout
	
	status_lbl.text = LocalizationManager.t("ONLINE")
	status_lbl.add_theme_color_override("font_color", Color(0.1, 0.8, 0.4))
	
	var time_dict = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [time_dict.hour, time_dict.minute]
	_add_message_bubble(text, false, time_str, true)
	_update_choices()

func _scroll_to_bottom() -> void:
	if scroll.get_v_scroll_bar():
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _update_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()
		
	var chat = MessageManager.get_chat(current_npc.id)
	if chat.is_empty() or chat[-1].sender == "player":
		return # No choices if waiting for NPC
		
	var last_msg = chat[-1].text
	
	if "target" in last_msg.to_lower() or "cash" in last_msg.to_lower():
		_add_choice("BTN_TAKE", "ILL_TAKE_IT", func():
			_player_replies("ILL_TAKE_IT")
			EconomyManager.add_money(500)
			RiskManager.add_risk(5.0)
			ReputationManager.add_reputation(10)
			ProgressionManager.add_xp(25)
		)
		_add_choice("BTN_NEGOTIATE", "NEED_MORE", func():
			_player_replies("NEED_MORE")
			RiskManager.add_risk(10.0)
			ReputationManager.add_reputation(-5)
			ProgressionManager.add_xp(35)
		)
		_add_choice("BTN_DECLINE", "PASS", func():
			_player_replies("PASS")
			ReputationManager.add_reputation(-15)
			ProgressionManager.add_xp(10)
		)
	else:
		_add_choice("BTN_ACK", "UNDERSTOOD", func():
			_player_replies("UNDERSTOOD")
		)

func _add_choice(label_key: String, reply_text_key: String, action: Callable) -> void:
	var btn = Button.new()
	btn.text = LocalizationManager.t(label_key)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size.y = 80
	btn.pressed.connect(func():
		AudioManager.play_ui_click()
		action.call()
		_update_choices()
	)
	choices_box.add_child(btn)

func _player_replies(text: String) -> void:
	MessageManager.send_message(current_npc.id, text)
	var time_dict = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [time_dict.hour, time_dict.minute]
	_add_message_bubble(text, true, time_str, true)
