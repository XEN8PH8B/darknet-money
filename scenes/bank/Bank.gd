extends Control

@onready var tab_container = $SafeAreaMargin/VBox/TabContainer
@onready var back_btn = $SafeAreaMargin/VBox/Header/BackBtn
@onready var tab_buttons = $SafeAreaMargin/VBox/TabButtons.get_children()

@onready var total_val = $SafeAreaMargin/VBox/TabContainer/Overview/BalanceCard/VBox/TotalVal
@onready var avail_val = $SafeAreaMargin/VBox/TabContainer/Overview/BalanceCard/VBox/HBox/AvailBox/AvailVal
@onready var frozen_val = $SafeAreaMargin/VBox/TabContainer/Overview/BalanceCard/VBox/HBox/FrozenBox/FrozenVal

@onready var recent_container = $SafeAreaMargin/VBox/TabContainer/Overview/RecentContainer
@onready var trans_list = $SafeAreaMargin/VBox/TabContainer/Transactions/Scroll/List

@onready var sec_slider = $SafeAreaMargin/VBox/TabContainer/Security/SecCard/VBox/SecSlider
@onready var sec_level_val = $SafeAreaMargin/VBox/TabContainer/Security/SecCard/VBox/LevelVal

var current_total: float = 0.0
var target_total: float = 0.0
var current_avail: float = 0.0
var target_avail: float = 0.0
var current_frozen: float = 0.0
var target_frozen: float = 0.0

func _ready() -> void:
	back_btn.pressed.connect(_on_back_pressed)
	
	for i in range(tab_buttons.size()):
		tab_buttons[i].pressed.connect(_on_tab_pressed.bind(i))
	
	BankManager.balance_changed.connect(_on_balance_changed)
	BankManager.transaction_created.connect(_on_transaction_created)
	BankManager.funds_frozen.connect(_on_funds_frozen)
	
	sec_slider.value_changed.connect(_on_sec_slider_changed)
	
	# Initial load
	_on_sec_slider_changed(BankManager.security_level)
	sec_slider.value = BankManager.security_level
	
	# No fake transaction needed
	
	_on_balance_changed(BankManager.get_total_balance(), BankManager.get_available_balance(), BankManager.get_frozen_funds())
	
	# Load transactions
	for t in BankManager.get_transactions():
		add_transaction_ui(t)
	
	_update_texts()
	switch_tab(0)

func _update_texts() -> void:
	back_btn.text = LocalizationManager.t("BACK")
	$SafeAreaMargin/VBox/Header/Title.text = LocalizationManager.t("SVT_BANK")
	tab_buttons[0].text = LocalizationManager.t("OVERVIEW")
	tab_buttons[1].text = LocalizationManager.t("TRANSACTIONS")
	tab_buttons[2].text = LocalizationManager.t("ACCOUNTS")
	tab_buttons[3].text = LocalizationManager.t("SECURITY")
	
	$SafeAreaMargin/VBox/TabContainer/Overview/BalanceCard/VBox/Title.text = LocalizationManager.t("TOTAL_BALANCE")
	$SafeAreaMargin/VBox/TabContainer/Overview/BalanceCard/VBox/HBox/AvailBox/Label.text = LocalizationManager.t("AVAILABLE")
	$SafeAreaMargin/VBox/TabContainer/Overview/BalanceCard/VBox/HBox/FrozenBox/Label.text = LocalizationManager.t("FROZEN")
	$SafeAreaMargin/VBox/TabContainer/Security/SecCard/VBox/Label.text = LocalizationManager.t("SECURITY_LEVEL")

func _process(_delta: float) -> void:
	pass

func _on_back_pressed() -> void:
	UIManager.switch_scene("res://scenes/main/Main.tscn")

func _on_tab_pressed(index: int) -> void:
	switch_tab(index)

func switch_tab(index: int) -> void:
	AudioManager.play_ui_click()
	tab_container.current_tab = index
	for i in range(tab_buttons.size()):
		if i == index:
			tab_buttons[i].modulate = Color(1.2, 1.2, 1.2, 1.0)
		else:
			tab_buttons[i].modulate = Color(0.6, 0.6, 0.6, 1.0)
	
	# Fade in the tab
	var tab = tab_container.get_child(index)
	tab.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(tab, "modulate:a", 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func _on_balance_changed(total: float, avail: float, frozen: float) -> void:
	target_total = total
	target_avail = avail
	target_frozen = frozen
	
	var t = create_tween()
	t.set_parallel(true)
	t.tween_method(_update_total, current_total, target_total, 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_method(_update_avail, current_avail, target_avail, 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	t.tween_method(_update_frozen, current_frozen, target_frozen, 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func _update_total(val: float) -> void:
	current_total = val
	total_val.text = "$%.2f" % val

func _update_avail(val: float) -> void:
	current_avail = val
	avail_val.text = "$%.2f" % val

func _update_frozen(val: float) -> void:
	current_frozen = val
	frozen_val.text = "$%.2f" % val

func _on_transaction_created(data: Dictionary) -> void:
	add_transaction_ui(data, true)

func add_transaction_ui(data: Dictionary, animate: bool = false) -> void:
	var panel = PanelContainer.new()
	var vbox = VBoxContainer.new()
	var header = HBoxContainer.new()
	var amount_lbl = Label.new()
	var desc_lbl = Label.new()
	var date_lbl = Label.new()
	
	panel.add_child(vbox)
	vbox.add_child(header)
	
	amount_lbl.text = ("+ " if data.amount > 0 else "- ") + "$%.2f" % abs(data.amount)
	amount_lbl.add_theme_color_override("font_color", Color(0.1, 0.8, 0.4) if data.amount > 0 else Color(0.9, 0.3, 0.3))
	amount_lbl.add_theme_font_size_override("font_size", 28)
	
	date_lbl.text = data.date + " " + data.time
	date_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	date_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	date_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	header.add_child(amount_lbl)
	header.add_child(date_lbl)
	
	var localized_desc = LocalizationManager.t(data.description.to_upper().replace(" ", "_"))
	if localized_desc == data.description.to_upper().replace(" ", "_"): localized_desc = data.description
	
	var localized_type = LocalizationManager.t(data.type.to_upper().replace(" ", "_"))
	if localized_type == data.type.to_upper().replace(" ", "_"): localized_type = data.type
	
	desc_lbl.text = localized_desc + " (" + localized_type + ")"
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(desc_lbl)
	
	trans_list.add_child(panel)
	trans_list.move_child(panel, 0)
	
	# Also add to recent in overview
	if recent_container.get_child_count() > 3:
		recent_container.get_child(recent_container.get_child_count()-1).queue_free()
		
	var recent_panel = panel.duplicate()
	recent_container.add_child(recent_panel)
	recent_container.move_child(recent_panel, 0)
	
	if animate:
		panel.modulate.a = 0.0
		panel.position.y -= 20
		var t = create_tween()
		t.set_parallel(true)
		t.tween_property(panel, "modulate:a", 1.0, 0.4)
		t.tween_property(panel, "position:y", panel.position.y + 20, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_funds_frozen(amount: float, reason: String) -> void:
	AudioManager.play_ui_click()
	AudioManager.vibrate("medium")
	# Could show a popup or highlight
	frozen_val.modulate = Color(2.0, 2.0, 2.0)
	var t = create_tween()
	t.tween_property(frozen_val, "modulate", Color(1.0, 1.0, 1.0), 0.5)

func _on_sec_slider_changed(value: float) -> void:
	var lvl = int(value)
	sec_level_val.text = str(lvl)
	BankManager.set_security_level(lvl)
