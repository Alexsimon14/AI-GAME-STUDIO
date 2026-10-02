extends RefCounted
## Explicit primitive schema; monetary integers never pass through JSON numbers.
const State = preload("res://scripts/domain/finance/finance_state.gd")
const Entry = preload("res://scripts/domain/finance/financial_entry.gd")
const Config = preload("res://resources/config/finance_config.gd")

func encode(state) -> Variant:
	if state == null: return null
	var entries: Array = []
	var ids: Array = state.entries.keys()
	ids.sort()
	for id in ids:
		var e = state.entries[id]
		entries.append({"id": e.id, "club_id": e.club_id, "season_id": e.season_id,
			"round_number": str(e.round_number), "category": e.category, "amount": str(e.amount),
			"operation_key": e.operation_key, "description_key": e.description_key, "context": _json_context(e.context)})
	var config: Dictionary = state.config_snapshot
	var occupancy: Dictionary = {}
	var maintenance: Dictionary = {}
	for profile in ["PEQUENO", "MEDIO", "ELITE"]:
		occupancy[profile] = str(config.occupancy_basis_points[profile])
		maintenance[profile] = str(config.maintenance_per_round[profile])
	return {"season_id": state.season_id, "baseline_committed_round": str(state.baseline_committed_round),
		"processed_rounds": state.processed_rounds.duplicate(true), "entries": entries,
		"config_snapshot": {"config_id": config.config_id, "purpose": config.purpose,
			"ticket_price": str(config.ticket_price), "occupancy_basis_points": occupancy, "maintenance_per_round": maintenance}}

func decode(data: Variant) -> Dictionary:
	if data == null: return {"state": null, "errors": PackedStringArray()}
	if not data is Dictionary or not data.get("season_id") is String or not _integer(data.get("baseline_committed_round")) or not data.get("entries") is Array or not data.get("processed_rounds") is Dictionary:
		return _failure("Invalid financial state fields.")
	if data.entries.size() > 10000: return _failure("Financial ledger exceeds schema limit.")
	var config = data.get("config_snapshot")
	if not config is Dictionary or config.size() != 5 or not config.get("config_id") is String or not config.get("purpose") is String or not _integer(config.get("ticket_price")):
		return _failure("Invalid financial configuration.")
	var snapshot := {"config_id": config.config_id, "purpose": config.purpose, "ticket_price": int(config.ticket_price)}
	for name in ["occupancy_basis_points", "maintenance_per_round"]:
		if not config.get(name) is Dictionary or config[name].size() != 3: return _failure("Invalid financial configuration map.")
		snapshot[name] = {}
		for profile in ["PEQUENO", "MEDIO", "ELITE"]:
			if not _integer(config[name].get(profile)): return _failure("Invalid financial configuration integer.")
			snapshot[name][profile] = int(config[name][profile])
	if not Config.validate_snapshot(snapshot).is_empty(): return _failure("Invalid financial configuration values.")
	var state = State.new()
	state.season_id = data.season_id
	state.baseline_committed_round = int(data.baseline_committed_round)
	state.config_snapshot = snapshot
	state.processed_rounds = data.processed_rounds.duplicate(true)
	for record in data.entries:
		if not record is Dictionary: return _failure("Invalid financial entry.")
		var entry = Entry.new()
		for field in ["id", "club_id", "season_id", "category", "operation_key", "description_key"]:
			if not record.get(field) is String: return _failure("Missing financial entry string: " + field)
			entry.set(field, record[field])
		for field in ["round_number", "amount"]:
			if not _integer(record.get(field)): return _failure("Expected canonical financial integer: " + field)
			entry.set(field, int(record[field]))
		var context: Dictionary = _parse_context(record.get("context"))
		if not context.errors.is_empty(): return _failure(context.errors[0])
		entry.context = context.value
		if state.entries.has(entry.id): return _failure("Duplicate financial entry ID.")
		state.entries[entry.id] = entry
	return {"state": state, "errors": PackedStringArray()}

func _integer(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(int(value)) == value

func _json_context(data: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key in data:
		output[key] = {"integer": str(data[key])} if data[key] is int else data[key]
	return output

func _parse_context(data: Variant) -> Dictionary:
	if not data is Dictionary: return {"errors": PackedStringArray(["Invalid financial context."])}
	var output: Dictionary = {}
	for key in data:
		if not key is String: return {"errors": PackedStringArray(["Invalid financial context key."])}
		var value = data[key]
		if value is Dictionary:
			if value.size() != 1 or not _integer(value.get("integer")): return {"errors": PackedStringArray(["Invalid financial context integer."])}
			output[key] = int(value.integer)
		elif value is String or value is bool:
			output[key] = value
		else: return {"errors": PackedStringArray(["Invalid financial context type."])}
	return {"value": output, "errors": PackedStringArray()}

func _failure(message: String) -> Dictionary:
	return {"state": null, "errors": PackedStringArray([message])}
