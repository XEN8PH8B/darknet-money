extends Control

@onready var time_label = $SafeAreaMargin/VBoxContainer/TopBar/TimeLabel
@onready var risk_label = $SafeAreaMargin/VBoxContainer/TopBar/RiskLabel
@onready var rep_label = $SafeAreaMargin/VBoxContainer/TopBar/RepLabel

@onready var wealth_label = $SafeAreaMargin/VBoxContainer/CenterArea/WealthLabel
@onready var today_label = $SafeAreaMargin/VBoxContainer/CenterArea/TodayLabel

@onready var bank_value = $SafeAreaMargin/VBoxContainer/StatsArea/BankCard/VBox/Value
@onready var cash_value = $SafeAreaMargin/VBoxContainer/StatsArea/CashCard/VBox/Value
@onready var risk_card_value = $SafeAreaMargin/VBoxContainer/StatsArea/RiskCard/VBox/Value

@onready var vbox_container = $SafeAreaMargin/VBoxContainer
@onready var bottom_nav = $BottomNav

var current_wealth: float = 0.0
var target_wealth: float = 0.0

func _ready() -> void:
	update_time()
	bind_button_animations(self)
	load_data()
	play_intro_animation()

func _process(_delta: float) -> void:
	update_time()

func update_time() -> void:
	var time_dict = Time.get_time_dict_from_system()
	time_label.text = "%02d:%02d" % [time_dict.hour, time_dict.minute]

func load_data() -> void:
	target_wealth = EconomyManager.get_money()
	var bank = SaveManager.get_value("bank_balance", 0.0)
	var cash = SaveManager.get_value("cash", 0.0)
	var risk = RiskManager.get_risk()
	var rep = ReputationManager.get_reputation()
	
	risk_label.text = LocalizationManager.t("RISK") + " %d%%" % int(risk)
	rep_label.text = LocalizationManager.t("REP") + " %d" % rep
	
	bank_value.text = "$%.2f" % bank
	cash_value.text = "$%.2f" % cash
	risk_card_value.text = "%d%%" % int(risk)
	
	var income_today = BankManager.get_income_today()
	today_label.text = "+$%.2f " % income_today + LocalizationManager.t("TODAY")

func _update_texts() -> void:
	$BottomNav/Margin/HBox/BankBtn.text = LocalizationManager.t("BANK")
	$BottomNav/Margin/HBox/WorkBtn.text = LocalizationManager.t("WORK")
	$BottomNav/Margin/HBox/MarketBtn.text = LocalizationManager.t("MARKET")
	$BottomNav/Margin/HBox/MessagesBtn.text = LocalizationManager.t("MESSAGES")
	$BottomNav/Margin/HBox/ProfileBtn.text = LocalizationManager.t("PROFILE")
	$SafeAreaMargin/VBoxContainer/CenterArea/WealthTitle.text = LocalizationManager.t("TOTAL_BALANCE")
	$SafeAreaMargin/VBoxContainer/StatsArea/BankCard/VBox/Title.text = LocalizationManager.t("BANK")
	$SafeAreaMargin/VBoxContainer/StatsArea/RiskCard/VBox/Title.text = LocalizationManager.t("RISK")
	$SafeAreaMargin/VBoxContainer/OperationsArea/Title.text = LocalizationManager.t("ACTIVE_OPERATIONS")

func play_intro_animation() -> void:
	var t = create_tween()
	t.set_parallel(true)
	
	for child in vbox_container.get_children():
		child.modulate.a = 0.0
		var index = child.get_index()
		t.tween_property(child, "modulate:a", 1.0, 0.6).set_delay(index * 0.1).set_trans(Tween.TRANS_SINE)
	
	bottom_nav.modulate.a = 0.0
	t.tween_property(bottom_nav, "modulate:a", 1.0, 0.8).set_delay(0.4).set_trans(Tween.TRANS_SINE)
	
	var count_tween = create_tween()
	count_tween.tween_method(update_wealth_label, 0.0, target_wealth, 2.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

func update_wealth_label(val: float) -> void:
	wealth_label.text = "$%.2f" % val

func bind_button_animations(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			child.button_down.connect(_on_btn_down.bind(child))
			child.button_up.connect(_on_btn_up.bind(child))
			child.mouse_entered.connect(_on_btn_hover.bind(child, true))
			child.mouse_exited.connect(_on_btn_hover.bind(child, false))
			
			if child.name == "ProfileBtn":
				child.pressed.connect(func(): UIManager.switch_scene("res://scenes/profile/Profile.tscn"))
			elif child.name == "BankBtn":
				child.pressed.connect(func(): UIManager.switch_scene("res://scenes/bank/Bank.tscn"))
			elif child.name == "MarketBtn":
				child.pressed.connect(func(): UIManager.switch_scene("res://scenes/market/Market.tscn"))
			elif child.name == "WorkBtn":
				child.pressed.connect(func(): UIManager.switch_scene("res://scenes/work/Work.tscn"))
			elif child.name == "MessagesBtn":
				child.pressed.connect(func(): UIManager.switch_scene("res://scenes/messages/Messages.tscn"))
		
		bind_button_animations(child)

func _on_btn_down(btn: Button) -> void:
	AudioManager.play_ui_click()
	AudioManager.vibrate("light")
	
	btn.pivot_offset = btn.size / 2
	var t = create_tween()
	t.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05).set_trans(Tween.TRANS_SINE)

func _on_btn_up(btn: Button) -> void:
	var t = create_tween()
	t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_btn_hover(btn: Button, hovered: bool) -> void:
	var t = create_tween()
	if hovered:
		t.tween_property(btn, "modulate", Color(1.2, 1.2, 1.2, 1.0), 0.1)
	else:
		t.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)

func _on_back_button_pressed() -> void:
	UIManager.switch_scene("res://scenes/boot/Boot.tscn")
