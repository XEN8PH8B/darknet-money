extends Node

const SAVE_PATH = "user://save_data.json"

var data : Dictionary = {
	"money": 0.0,
	"bank_balance": 0.0,
	"cash": 0.0,
	"frozen_funds": 0.0,
	"level": 1,
	"xp": 0.0,
	"risk": 0.0,
	"attention": 0.0,
	"reputation": 0,
	"influence": 0,
	"unlocked_features": [],
	"settings": {}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data)
		file.store_line(json_string)
		file.close()
		print("Game saved successfully.")
	else:
		push_error("Failed to save game.")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found, starting fresh.")
		save_game()
		return
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			if typeof(json.data) == TYPE_DICTIONARY:
				var loaded_data = json.data as Dictionary
				# Merge loaded data to keep default keys if any are missing
				for key in loaded_data.keys():
					data[key] = loaded_data[key]
				print("Game loaded successfully.")
			else:
				push_error("Save file is not a valid JSON dictionary.")
		else:
			push_error("JSON Parse Error: " + json.get_error_message() + " in " + json_string + " at line " + str(json.get_error_line()))
		file.close()
	else:
		push_error("Failed to load game.")

func get_value(key: String, default_val = null):
	return data.get(key, default_val)

func set_value(key: String, value) -> void:
	data[key] = value
