extends Node

signal reputation_changed(new_rep)
signal attention_changed(new_attention)

func get_reputation() -> int:
	return SaveManager.get_value("reputation", 0)

func get_attention() -> float:
	return SaveManager.get_value("attention", 0.0)

func add_reputation(amount: int) -> void:
	var current = get_reputation()
	var val = current + amount
	SaveManager.set_value("reputation", val)
	SaveManager.save_game()
	reputation_changed.emit(val)

func add_attention(amount: float) -> void:
	var current = get_attention()
	var val = clamp(current + amount, 0.0, 100.0)
	SaveManager.set_value("attention", val)
	SaveManager.save_game()
	attention_changed.emit(val)
