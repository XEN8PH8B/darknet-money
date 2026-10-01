extends Node

signal balance_changed(new_balance, available, frozen)
signal transaction_created(transaction_data)
signal funds_frozen(amount, reason)
signal funds_unfrozen(amount)
signal bank_event_created(event_type)

var security_level: int = 1

func _ready() -> void:
	security_level = SaveManager.get_value("bank_security_level", 1)
	if SaveManager.get_value("transactions", null) == null:
		SaveManager.set_value("transactions", [])

func get_total_balance() -> float:
	return SaveManager.get_value("bank_balance", 0.0)

func get_frozen_funds() -> float:
	return SaveManager.get_value("frozen_funds", 0.0)

func get_available_balance() -> float:
	return max(0, get_total_balance() - get_frozen_funds())

func get_transactions() -> Array:
	return SaveManager.get_value("transactions", [])

func get_income_today() -> float:
	return SaveManager.get_value("income_today", 0.0)

func set_security_level(level: int) -> void:
	security_level = clamp(level, 1, 5)
	SaveManager.set_value("bank_security_level", security_level)
	SaveManager.save_game()

func process_transaction(amount: float, type: String, description: String, status: String = "completed") -> void:
	var total = get_total_balance()
	total += amount
	SaveManager.set_value("bank_balance", total)
	
	if amount > 0:
		var today = get_income_today()
		SaveManager.set_value("income_today", today + amount)
	
	var time_dict = Time.get_datetime_dict_from_system()
	var date_str = "%02d.%02d.%d" % [time_dict.day, time_dict.month, time_dict.year]
	var time_str = "%02d:%02d" % [time_dict.hour, time_dict.minute]
	
	var t = {
		"date": date_str,
		"time": time_str,
		"amount": amount,
		"type": type,
		"description": description,
		"status": status
	}
	
	var txs = get_transactions()
	txs.push_front(t)
	if txs.size() > 50:
		txs.resize(50)
		
	ProgressionManager.add_xp(10)
		
	SaveManager.set_value("transactions", txs)
	SaveManager.save_game()
	
	balance_changed.emit(total, get_available_balance(), get_frozen_funds())
	transaction_created.emit(t)
	
	# Bank Events Logic based on security level
	# Lower security = higher chance of hold
	var hold_chance = max(0.01, 0.20 - (security_level * 0.03))
	if amount > 10000 and randf() < hold_chance:
		trigger_bank_event("TEMPORARY HOLD", amount)

func freeze_funds(amount: float, reason: String) -> void:
	var current = get_frozen_funds()
	SaveManager.set_value("frozen_funds", current + amount)
	SaveManager.save_game()
	funds_frozen.emit(amount, reason)
	balance_changed.emit(get_total_balance(), get_available_balance(), get_frozen_funds())

func unfreeze_funds(amount: float) -> void:
	var current = get_frozen_funds()
	SaveManager.set_value("frozen_funds", max(0, current - amount))
	SaveManager.save_game()
	funds_unfrozen.emit(amount)
	balance_changed.emit(get_total_balance(), get_available_balance(), get_frozen_funds())

func trigger_bank_event(event_type: String, related_amount: float = 0.0) -> void:
	bank_event_created.emit(event_type)
	NotificationManager.notify("BANK EVENT", event_type, "alert")
	
	if event_type == "TEMPORARY HOLD":
		freeze_funds(related_amount, "Security check")
	elif event_type == "ACCOUNT REVIEW":
		RiskManager.add_risk(5.0)
