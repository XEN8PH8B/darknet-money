extends Node

var npcs: Dictionary = {}

func _ready() -> void:
	_init_npcs()

func _init_npcs() -> void:
	var broker = NPCData.new()
	broker.id = "broker"
	broker.name = "BROKER"
	broker.avatar = _load_avatar("broker_avatar_1790875273827.jpg")
	broker.relationship = 0
	broker.reputation = 50
	npcs[broker.id] = broker

	var fixer = NPCData.new()
	fixer.id = "fixer"
	fixer.name = "FIXER"
	fixer.avatar = _load_avatar("fixer_avatar_1790875284529.jpg")
	fixer.relationship = 10
	fixer.reputation = 30
	npcs[fixer.id] = fixer

	var investor = NPCData.new()
	investor.id = "investor"
	investor.name = "INVESTOR"
	investor.avatar = _load_avatar("investor_avatar_1790875294746.jpg")
	investor.relationship = 0
	investor.reputation = 200
	npcs[investor.id] = investor

	var rival = NPCData.new()
	rival.id = "rival"
	rival.name = "RIVAL"
	rival.avatar = _load_avatar("rival_avatar_1790875311312.jpg")
	rival.relationship = -50
	rival.reputation = 100
	npcs[rival.id] = rival

	var bank = NPCData.new()
	bank.id = "bank_manager"
	bank.name = "BANK MANAGER"
	bank.avatar = _load_avatar("bank_manager_avatar_1790875319574.jpg")
	bank.relationship = 0
	bank.reputation = 500
	npcs[bank.id] = bank

	var unknown = NPCData.new()
	unknown.id = "unknown"
	unknown.name = "UNKNOWN"
	unknown.avatar = _load_avatar("unknown_avatar_1790875330648.jpg")
	unknown.relationship = 0
	unknown.reputation = 0
	npcs[unknown.id] = unknown

func _load_avatar(filename: String) -> Texture2D:
	var path = "res://assets/avatars/" + filename
	# In Godot 4.x running from source, FileAccess or Image load works for external files
	var img = Image.new()
	var err = img.load(path)
	if err == OK:
		return ImageTexture.create_from_image(img)
	return null

func get_npc(id: String) -> NPCData:
	return npcs.get(id, null)
