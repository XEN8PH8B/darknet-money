extends Node

signal level_up(new_level, title)
signal achievement_unlocked(id, title)
signal xp_gained(amount, total)

var current_level: int = 1
var current_xp: int = 0
var influence: int = 0
var unlocked_achievements: Array = []

var level_titles = {
	1: "UNKNOWN",
	5: "SMALL OPERATOR",
	10: "CONNECTED",
	20: "INFLUENTIAL",
	35: "UNDERGROUND BOSS",
	50: "SHADOW EMPIRE"
}

var achievements_db = {
	"first_1k": {"title": "FIRST $1,000", "desc": "Accumulate your first $1,000."},
	"first_100k": {"title": "FIRST $100,000", "desc": "Accumulate $100,000."},
	"millionaire": {"title": "MILLIONAIRE", "desc": "Reach $1,000,000 in wealth."},
	"high_risk": {"title": "HIGH RISK", "desc": "Reach 85% Risk level."},
	"survivor": {"title": "SURVIVOR", "desc": "Survive a Lockdown event."},
	"shadow_empire": {"title": "SHADOW EMPIRE", "desc": "Reach Level 50."}
}

func _ready() -> void:
	current_level = SaveManager.get_value("level", 1)
	current_xp = SaveManager.get_value("xp", 0)
	influence = SaveManager.get_value("influence", 0)
	unlocked_achievements = SaveManager.get_value("achievements", [])
	
	EconomyManager.money_changed.connect(_on_money_changed)
	RiskManager.risk_changed.connect(_on_risk_changed)

func add_xp(amount: int) -> void:
	current_xp += amount
	xp_gained.emit(amount, current_xp)
	
	var new_level = _calculate_level(current_xp)
	if new_level > current_level:
		current_level = new_level
		var title = get_title_for_level(current_level)
		level_up.emit(current_level, title)
		NotificationManager.notify("LEVEL UP", "You reached Level %d: %s" % [current_level, title], "success")
		if current_level >= 50:
			unlock_achievement("shadow_empire")
			
	_save_progression()

func _calculate_level(xp: int) -> int:
	return int(floor(pow(xp / 100.0, 0.5))) + 1

func get_title_for_level(lvl: int) -> String:
	var best_title = "UNKNOWN"
	var sorted_keys = level_titles.keys()
	sorted_keys.sort()
	for k in sorted_keys:
		if lvl >= k:
			best_title = level_titles[k]
	return best_title

func unlock_achievement(id: String) -> void:
	if not achievements_db.has(id): return
	if unlocked_achievements.has(id): return
	
	unlocked_achievements.append(id)
	_save_progression()
	
	var data = achievements_db[id]
	achievement_unlocked.emit(id, data.title)
	
	var popup_scene = load("res://scenes/achievements/AchievementPopup.tscn")
	if popup_scene:
		var popup = popup_scene.instantiate()
		get_tree().root.add_child(popup)
		popup.setup(data.title, data.desc)

func _on_money_changed(amount: float) -> void:
	if amount >= 1000.0:
		unlock_achievement("first_1k")
	if amount >= 100000.0:
		unlock_achievement("first_100k")
	if amount >= 1000000.0:
		unlock_achievement("millionaire")

func _on_risk_changed(risk: float, _state: String) -> void:
	if risk >= 85.0:
		unlock_achievement("high_risk")

func add_influence(amount: int) -> void:
	influence += amount
	_save_progression()

func _save_progression() -> void:
	SaveManager.set_value("level", current_level)
	SaveManager.set_value("xp", current_xp)
	SaveManager.set_value("influence", influence)
	SaveManager.set_value("achievements", unlocked_achievements)
	SaveManager.save_game()
