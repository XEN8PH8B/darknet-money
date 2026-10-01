extends Node

var events_db: Dictionary = {}

func _ready() -> void:
	_init_events()

func _init_events() -> void:
	var ev1 = EventData.new()
	ev1.id = "ACCOUNT REVIEW"
	ev1.title = "ACCOUNT REVIEW"
	ev1.description = "Bank compliance has flagged recent transactions. An audit is imminent."
	ev1.choices = [
		{"label": "BRIBE AUDITOR ($5K)", "cost": 5000.0, "risk_change": -10.0, "rep_change": -5},
		{"label": "WAIT IT OUT", "cost": 0.0, "risk_change": 15.0, "rep_change": 0}
	]
	events_db[ev1.id] = ev1

	var ev2 = EventData.new()
	ev2.id = "MARKET RAID"
	ev2.title = "MARKET RAID"
	ev2.description = "Authorities are cracking down on underground nodes."
	ev2.choices = [
		{"label": "BURN SERVERS ($2.5K)", "cost": 2500.0, "risk_change": -20.0, "rep_change": 0},
		{"label": "DEFEND NODE", "cost": 0.0, "risk_change": 25.0, "rep_change": 50}
	]
	events_db[ev2.id] = ev2

	var ev3 = EventData.new()
	ev3.id = "NETWORK SHUTDOWN"
	ev3.title = "NETWORK SHUTDOWN"
	ev3.description = "Total lockdown initialized. Operations suspended."
	ev3.choices = [
		{"label": "INITIATE PROTOCOL OMEGA ($10K)", "cost": 10000.0, "risk_change": -50.0, "rep_change": 100}
	]
	events_db[ev3.id] = ev3

func trigger_event(event_id: String) -> void:
	if not events_db.has(event_id): return
	var data = events_db[event_id]
	
	var modal_scene = load("res://scenes/event/EventModal.tscn")
	var modal = modal_scene.instantiate()
	get_tree().root.add_child(modal)
	modal.setup(data)
