extends Node

signal risk_changed(new_risk, state_name)
signal lockdown_triggered()

func get_risk() -> float:
	return SaveManager.get_value("risk", 0.0)

func add_risk(amount: float) -> void:
	var current = get_risk()
	var new_risk = clamp(current + amount, 0.0, 100.0)
	SaveManager.set_value("risk", new_risk)
	SaveManager.save_game()
	
	var state = get_risk_state()
	risk_changed.emit(new_risk, state)
	
	if state == "LOCKDOWN" and current < 100.0:
		trigger_lockdown()

func get_risk_state() -> String:
	var r = get_risk()
	if r < 50: return "NORMAL"
	elif r < 70: return "WARNING"
	elif r < 85: return "HIGH ATTENTION"
	elif r < 100: return "CRITICAL"
	else: return "LOCKDOWN"

func trigger_lockdown() -> void:
	lockdown_triggered.emit()
	UIManager.shake_screen(15.0, 0.8)
	AudioManager.vibrate("error")
	BankManager.freeze_funds(BankManager.get_available_balance() * 0.5, "SYSTEM LOCKDOWN")
	EventManager.trigger_event("NETWORK SHUTDOWN")

func _process(_delta: float) -> void:
	if randf() < 0.001:
		add_risk(-0.01)

func roll_for_event(probability: float) -> bool:
	return randf() <= probability
