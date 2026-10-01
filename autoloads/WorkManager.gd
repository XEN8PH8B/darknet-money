extends Node

signal operation_started(op_id)
signal operation_completed(op_id, profit)
signal operation_event_triggered(op_id, event_type)
signal operations_updated()

var available_operations: Dictionary = {}
var active_operations: Array = []

func _ready() -> void:
	_init_operations()
	_load_active_operations()

func _init_operations() -> void:
	var op1 = OperationData.new()
	op1.id = "network_push"
	op1.title = "NETWORK PUSH"
	op1.description = "Establish a basic datalink for an anonymous client."
	op1.cost = 250
	op1.min_reward = 400
	op1.max_reward = 700
	op1.duration = 60
	op1.risk = 0.12
	op1.required_level = 1
	op1.required_reputation = 0
	available_operations[op1.id] = op1

	var op2 = OperationData.new()
	op2.id = "shadow_market"
	op2.title = "SHADOW MARKET"
	op2.description = "Broker a temporary exchange node for undisclosed assets."
	op2.cost = 2500
	op2.min_reward = 3000
	op2.max_reward = 8000
	op2.duration = 300
	op2.risk = 0.34
	op2.required_level = 1
	op2.required_reputation = 0
	available_operations[op2.id] = op2

	var op3 = OperationData.new()
	op3.id = "black_channel"
	op3.title = "BLACK CHANNEL"
	op3.description = "Route massive funds through decentralized networks."
	op3.cost = 15000
	op3.min_reward = 20000
	op3.max_reward = 70000
	op3.duration = 1800
	op3.risk = 0.71
	op3.required_level = 1
	op3.required_reputation = 0
	available_operations[op3.id] = op3

	var op4 = OperationData.new()
	op4.id = "underground_syndicate"
	op4.title = "UNDERGROUND SYNDICATE"
	op4.description = "Coordinate a multi-node structural takeover."
	op4.cost = 100000
	op4.min_reward = 150000
	op4.max_reward = 600000
	op4.duration = 7200
	op4.risk = 0.94
	op4.required_level = 1
	op4.required_reputation = 0
	available_operations[op4.id] = op4

func _load_active_operations() -> void:
	active_operations = SaveManager.get_value("active_operations", [])

func _save_active_operations() -> void:
	SaveManager.set_value("active_operations", active_operations)
	SaveManager.save_game()

func start_operation(op_id: String) -> bool:
	if not available_operations.has(op_id): return false
	var op = available_operations[op_id]
	if EconomyManager.get_money() < op.cost: return false
	
	EconomyManager.add_money(-op.cost)
	
	var active_op = {
		"instance_id": str(Time.get_unix_time_from_system()) + str(randi() % 1000),
		"op_id": op_id,
		"start_time": Time.get_unix_time_from_system(),
		"projected_income": randf_range(op.min_reward, op.max_reward),
		"active_event": "",
		"state": "running"
	}
	active_operations.append(active_op)
	
	if op.cost >= 100000:
		RiskManager.add_risk(12.0)
	elif op.cost >= 15000:
		RiskManager.add_risk(8.0)
	else:
		RiskManager.add_risk(2.0)
		
	_save_active_operations()
	operation_started.emit(active_op["instance_id"])
	operations_updated.emit()
	return true

func _process(_delta: float) -> void:
	if active_operations.is_empty(): return
	var current_time = Time.get_unix_time_from_system()
	var changed = false
	var to_remove = []
	
	for op in active_operations:
		if op.state == "completed": 
			to_remove.append(op)
			continue
			
		var op_data = available_operations[op.op_id]
		var elapsed = current_time - op.start_time
		
		if op.state == "running":
			if elapsed < op_data.duration - 10 and randf() < 0.005 * _delta and op.active_event == "":
				trigger_random_event(op)
				changed = true
			
			if elapsed >= op_data.duration:
				op.state = "completed"
				var profit = op.projected_income
				BankManager.process_transaction(profit, "Operation Income", op_data.title)
				EconomyManager.add_money(profit)
				RiskManager.add_risk(1.0) # success operation: +1%
				ProgressionManager.add_xp(int(profit * 0.1))
				operation_completed.emit(op.instance_id, profit)
				NotificationManager.notify(LocalizationManager.t("OPERATION COMPLETE"), LocalizationManager.t("PROFIT_BANKED") % profit, "success")
				to_remove.append(op)
				changed = true

	for op in to_remove:
		active_operations.erase(op)

	if changed or to_remove.size() > 0:
		_save_active_operations()
		operations_updated.emit()

func trigger_random_event(op: Dictionary) -> void:
	var events = ["CONTACT DISCONNECTED", "MARKET SHIFT", "RISK INCREASED", "BONUS OPPORTUNITY", "PAYMENT DELAYED"]
	op.active_event = events[randi() % events.size()]
	op.state = "paused_by_event"
	op.pause_start_time = Time.get_unix_time_from_system()
	RiskManager.add_risk(-1.0) # pause: -1%
	NotificationManager.notify(LocalizationManager.t("OPERATION EVENT"), LocalizationManager.t("ACTION_REQUIRED") + LocalizationManager.t(op.active_event), "warning")
	operation_event_triggered.emit(op.instance_id, op.active_event)

func resolve_event(instance_id: String, resolution: String) -> void:
	for op in active_operations:
		if op.instance_id == instance_id:
			var paused_time = Time.get_unix_time_from_system() - op.get("pause_start_time", Time.get_unix_time_from_system())
			op.start_time += paused_time # Shift the start time to account for pause
			
			if resolution == "pay_fee":
				if EconomyManager.get_money() >= 500:
					EconomyManager.add_money(-500.0)
				else:
					NotificationManager.notify(LocalizationManager.t("ERROR"), LocalizationManager.t("NOT_ENOUGH_FUNDS"), "error")
					return # Don't resolve, force them to take risk
			elif resolution == "take_risk":
				RiskManager.add_risk(10.0)
			
			if op.active_event == "RISK INCREASED" and resolution != "pay_fee":
				RiskManager.add_risk(5.0)
			elif op.active_event == "BONUS OPPORTUNITY" and resolution == "take_risk":
				op.projected_income *= 1.2
			elif op.active_event == "PAYMENT DELAYED":
				op.start_time += 60 # Extra minute
				
			op.active_event = ""
			op.state = "running"
			
			_save_active_operations()
			operations_updated.emit()
			return

func get_active_operations() -> Array:
	return active_operations
