extends Node

signal notification_received(title, message, type)

func notify(title: String, message: String, type: String = "info") -> void:
	notification_received.emit(title, message, type)
	print("NOTIFICATION: [%s] %s - %s" % [type, title, message])
