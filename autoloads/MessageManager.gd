extends Node

signal message_received(npc_id, text)
signal chat_updated(npc_id)
signal unread_count_changed(count)

var chats: Dictionary = {}

func _ready() -> void:
	chats = SaveManager.get_value("chats", {})
	_ensure_chats_exist()

func _ensure_chats_exist() -> void:
	var npcs = ["broker", "fixer", "investor", "rival", "bank_manager", "unknown"]
	for n in npcs:
		if not chats.has(n):
			chats[n] = {"messages": [], "unread": 0}

func receive_message(npc_id: String, text: String, notify: bool = true) -> void:
	if not chats.has(npc_id):
		_ensure_chats_exist()
	
	var time_dict = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [time_dict.hour, time_dict.minute]
	
	chats[npc_id].messages.append({
		"sender": "npc",
		"text": text,
		"timestamp": time_str,
		"read": false
	})
	chats[npc_id].unread += 1
	
	_save_chats()
	
	if notify:
		AudioManager.play_ui_click()
		if OS.get_name() == "iOS" or OS.get_name() == "Android":
			Input.vibrate_handheld(30)
		var npc = NPCManager.get_npc(npc_id)
		var sender_name = npc.name if npc else npc_id.capitalize()
		NotificationManager.notify("NEW MESSAGE", "From " + sender_name, "info")
	
	message_received.emit(npc_id, text)
	chat_updated.emit(npc_id)
	unread_count_changed.emit(get_total_unread())

func send_message(npc_id: String, text: String) -> void:
	var time_dict = Time.get_time_dict_from_system()
	var time_str = "%02d:%02d" % [time_dict.hour, time_dict.minute]
	
	chats[npc_id].messages.append({
		"sender": "player",
		"text": text,
		"timestamp": time_str,
		"read": true
	})
	
	_save_chats()
	chat_updated.emit(npc_id)

func mark_chat_read(npc_id: String) -> void:
	if chats.has(npc_id):
		chats[npc_id].unread = 0
		for m in chats[npc_id].messages:
			m.read = true
		_save_chats()
		unread_count_changed.emit(get_total_unread())

func get_total_unread() -> int:
	var total = 0
	for chat in chats.values():
		total += chat.unread
	return total

func get_chat(npc_id: String) -> Array:
	return chats.get(npc_id, {}).get("messages", [])

func _save_chats() -> void:
	SaveManager.set_value("chats", chats)
	SaveManager.save_game()

func simulate_incoming() -> void:
	receive_message("broker", "I have a new target for you. Network push, low risk.")
	receive_message("fixer", "Need some clean cash fast. Interested?")
