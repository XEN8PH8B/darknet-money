extends Control

@onready var back_btn = $SafeAreaMargin/VBox/Header/BackBtn
@onready var sim_btn = $SafeAreaMargin/VBox/Header/SimulateBtn
@onready var chat_list = $SafeAreaMargin/VBox/Scroll/ChatList

func _ready() -> void:
	back_btn.pressed.connect(func(): UIManager.switch_scene("res://scenes/main/Main.tscn"))
	sim_btn.pressed.connect(func(): MessageManager.simulate_incoming())
	
	MessageManager.chat_updated.connect(func(_id): _build_list())
	_update_texts()
	_build_list()

func _update_texts() -> void:
	back_btn.text = LocalizationManager.t("BACK")
	sim_btn.text = LocalizationManager.t("SIMULATE")
	$SafeAreaMargin/VBox/Header/Title.text = LocalizationManager.t("MESSAGES")

func _build_list() -> void:
	for child in chat_list.get_children():
		child.queue_free()
		
	var sorted_npcs = ["broker", "fixer", "investor", "rival", "bank_manager", "unknown"]
	
	for npc_id in sorted_npcs:
		var npc = NPCManager.get_npc(npc_id)
		var chat_data = MessageManager.chats.get(npc_id, {"messages": [], "unread": 0})
		if chat_data.messages.is_empty() and chat_data.unread == 0:
			continue # Hide empty chats until interacted or message received
			
		var item = _create_chat_item(npc, chat_data)
		chat_list.add_child(item)

func _create_chat_item(npc: NPCData, chat_data: Dictionary) -> Control:
	var btn = Button.new()
	btn.custom_minimum_size.y = 120
	btn.add_theme_stylebox_override("normal", preload("res://DARKNET_THEME.tres").get_stylebox("panel", "PanelContainer"))
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 24)
	btn.add_child(hbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	hbox.add_child(margin)
	
	var inner_hbox = HBoxContainer.new()
	inner_hbox.add_theme_constant_override("separation", 24)
	margin.add_child(inner_hbox)
	
	var tex = TextureRect.new()
	tex.texture = npc.avatar
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.custom_minimum_size = Vector2(88, 88)
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	inner_hbox.add_child(tex)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	inner_hbox.add_child(vbox)
	
	var name_lbl = Label.new()
	name_lbl.text = LocalizationManager.t(npc.name.to_upper().replace(" ", "_"))
	name_lbl.add_theme_font_size_override("font_size", 28)
	name_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(name_lbl)
	
	var last_msg = Label.new()
	if chat_data.messages.size() > 0:
		var last = chat_data.messages[-1]
		var localized_text = LocalizationManager.t(last.text)
		last_msg.text = localized_text.substr(0, 40) + ("..." if localized_text.length() > 40 else "")
		if chat_data.unread > 0:
			last_msg.add_theme_color_override("font_color", Color(0.1, 0.8, 0.4))
		else:
			last_msg.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	else:
		last_msg.text = "No messages"
		last_msg.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
	last_msg.clip_text = true
	vbox.add_child(last_msg)
	
	if chat_data.unread > 0:
		var badge = Label.new()
		badge.text = str(chat_data.unread)
		badge.add_theme_color_override("font_color", Color(1, 1, 1))
		badge.add_theme_font_size_override("font_size", 24)
		var badge_bg = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.9, 0.2, 0.2)
		sb.corner_radius_top_left = 20
		sb.corner_radius_top_right = 20
		sb.corner_radius_bottom_left = 20
		sb.corner_radius_bottom_right = 20
		badge_bg.add_theme_stylebox_override("panel", sb)
		badge_bg.add_child(badge)
		inner_hbox.add_child(badge_bg)
	
	btn.pressed.connect(func():
		GameManager.current_chat_npc_id = npc.id
		UIManager.switch_scene("res://scenes/messages/Chat.tscn")
	)
	
	return btn
