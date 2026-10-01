extends Control

@onready var back_btn = $SafeAreaMargin/VBox/Header/BackBtn
@onready var title_lbl = $SafeAreaMargin/VBox/Header/Title
@onready var list = $SafeAreaMargin/VBox/Scroll/List

func _ready() -> void:
	back_btn.pressed.connect(func(): UIManager.switch_scene("res://scenes/main/Main.tscn"))
	_update_texts()
	
	var label = Label.new()
	label.text = LocalizationManager.t("MARKET_COMING_SOON")
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	list.add_child(label)

func _update_texts() -> void:
	back_btn.text = LocalizationManager.t("BACK")
	title_lbl.text = LocalizationManager.t("MARKET")
