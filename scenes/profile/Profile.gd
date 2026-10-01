extends Control

@onready var back_btn = $SafeAreaMargin/VBox/Header/BackBtn
@onready var lang_en = $SafeAreaMargin/VBox/SettingsPanel/VBox/LangBox/LangEn
@onready var lang_ru = $SafeAreaMargin/VBox/SettingsPanel/VBox/LangBox/LangRu
@onready var lang_ua = $SafeAreaMargin/VBox/SettingsPanel/VBox/LangBox/LangUa

@onready var title_lbl = $SafeAreaMargin/VBox/Header/Title
@onready var lang_title = $SafeAreaMargin/VBox/SettingsPanel/VBox/LangTitle

func _ready() -> void:
	back_btn.pressed.connect(func(): UIManager.switch_scene("res://scenes/main/Main.tscn"))
	
	lang_en.pressed.connect(func(): _set_language("en"))
	lang_ru.pressed.connect(func(): _set_language("ru"))
	lang_ua.pressed.connect(func(): _set_language("ua"))
	
	_bind_button_animation(lang_en)
	_bind_button_animation(lang_ru)
	_bind_button_animation(lang_ua)
	_bind_button_animation(back_btn)
	
	var current_lang = SaveManager.get_value("language", "en")
	_update_lang_visuals(current_lang)
	_update_texts()

func _update_texts() -> void:
	back_btn.text = LocalizationManager.t("BACK")
	title_lbl.text = LocalizationManager.t("PROFILE")
	lang_title.text = LocalizationManager.t("SYSTEM_LANGUAGE")

func _set_language(lang: String) -> void:
	SaveManager.set_value("language", lang)
	SaveManager.save_game()
	LocalizationManager.current_lang = lang
	_update_lang_visuals(lang)
	_update_texts()
	NotificationManager.notify(LocalizationManager.t("SYSTEM_LANGUAGE"), LocalizationManager.t("LANG_CHANGED"), "success")

func _update_lang_visuals(lang: String) -> void:
	lang_en.modulate = Color(1.2, 1.2, 1.2) if lang == "en" else Color(0.5, 0.5, 0.5)
	lang_ru.modulate = Color(1.2, 1.2, 1.2) if lang == "ru" else Color(0.5, 0.5, 0.5)
	lang_ua.modulate = Color(1.2, 1.2, 1.2) if lang == "ua" else Color(0.5, 0.5, 0.5)

func _bind_button_animation(btn: Button) -> void:
	btn.button_down.connect(func(): 
		AudioManager.play_ui_click()
		AudioManager.vibrate("light")
		btn.pivot_offset = btn.size / 2
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.05).set_trans(Tween.TRANS_SINE)
	)
	btn.button_up.connect(func():
		var t = create_tween()
		t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)
