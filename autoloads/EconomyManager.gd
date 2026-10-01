extends Node

signal money_changed(new_amount)
signal bank_balance_changed(new_amount)

func _ready() -> void:
	pass

func get_money() -> float:
	return SaveManager.get_value("money", 0.0)

func add_money(amount: float) -> void:
	var current = get_money()
	var new_money = current + amount
	SaveManager.set_value("money", new_money)
	SaveManager.save_game()
	money_changed.emit(new_money)
