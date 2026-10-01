extends Node

signal level_changed(new_level)
signal risk_changed(new_risk)
signal reputation_changed(new_rep)

var current_chat_npc_id: String = ""

func _ready() -> void:
	if SaveManager.get_value("first_launch", true):
		SaveManager.set_value("first_launch", false)
		EconomyManager.add_money(500.0)
		SaveManager.save_game()

func get_level() -> int:
	return SaveManager.get_value("level", 1)

func get_risk() -> float:
	return SaveManager.get_value("risk", 0.0)

func get_reputation() -> int:
	return SaveManager.get_value("reputation", 0)

func add_reputation(amount: int) -> void:
	var current = get_reputation()
	var new_rep = current + amount
	SaveManager.set_value("reputation", new_rep)
	SaveManager.save_game()
	reputation_changed.emit(new_rep)

func set_risk(amount: float) -> void:
	SaveManager.set_value("risk", amount)
	SaveManager.save_game()
	risk_changed.emit(amount)
