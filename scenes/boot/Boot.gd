extends Control

@onready var money_label: Label = $SafeAreaMargin/VBoxContainer/MoneyLabel
@onready var level_label: Label = $SafeAreaMargin/VBoxContainer/LevelLabel
@onready var risk_label: Label = $SafeAreaMargin/VBoxContainer/RiskLabel
@onready var reputation_label: Label = $SafeAreaMargin/VBoxContainer/ReputationLabel

func _ready() -> void:
	update_ui()

func update_ui() -> void:
	var money = EconomyManager.get_money()
	money_label.text = "$%.2f" % money
	
	var level = GameManager.get_level()
	level_label.text = LocalizationManager.t("LEVEL") + " %d" % level
	
	var risk = RiskManager.get_risk()
	risk_label.text = LocalizationManager.t("RISK") + " %d%%" % int(risk)
	
	var rep = ReputationManager.get_reputation()
	reputation_label.text = LocalizationManager.t("REP") + " %d" % rep

func _on_enter_button_pressed() -> void:
	UIManager.switch_scene("res://scenes/main/Main.tscn")
