extends RefCounted
const Config = preload("res://resources/config/finance_config.gd")
const DefaultConfig = preload("res://resources/config/finance_config.tres")
const State = preload("res://scripts/domain/finance/finance_state.gd")
const Entry = preload("res://scripts/domain/finance/financial_entry.gd")
const Validator = preload("res://scripts/domain/finance/finance_validator.gd")

func initialize(world: Variant, config: Variant = DefaultConfig, baseline_committed_round: int = 0) -> Dictionary:
	if world == null or world.season == null or world.finance != null:
		return _failure("Finance initialization requires an uninitialized competition world.")
	var world_errors: PackedStringArray = world.validation_errors()
	if not world_errors.is_empty():
		return {"ok": false, "errors": world_errors}
	if not config is Config:
		return _failure("Invalid finance configuration Resource.")
	var errors: PackedStringArray = config.validation_errors()
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var state := State.new()
	state.config_snapshot = config.snapshot()
	state.season_id = world.season.id
	state.baseline_committed_round = baseline_committed_round
	var descriptors: Array = []
	var clubs: Array = world.clubs.keys()
	clubs.sort()
	for club_id in clubs:
		descriptors.append(_descriptor(state, club_id, baseline_committed_round, "OPENING_BALANCE", world.clubs[club_id].cash, {"baseline_committed_round": baseline_committed_round}))
	return _commit(world, state, descriptors)

func process_round(world: Variant, round_number: int) -> Dictionary:
	if world == null or world.finance == null or world.season == null:
		return _failure("Finance is not initialized.")
	var errors: PackedStringArray = world.validation_errors()
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	if round_number < 1 or round_number > 10 or world.season.round_states.get(str(round_number)) != "COMMITTED":
		return _failure("Finance requires a committed round after its baseline.")
	if round_number <= world.finance.baseline_committed_round:
		return {"ok": true, "idempotent": true, "before_baseline": true, "errors": PackedStringArray()}
	# Financial rounds cannot skip an unprocessed predecessor.
	for earlier in range(world.finance.baseline_committed_round + 1, round_number):
		if world.finance.processed_rounds.get(str(earlier)) != true:
			return _failure("An earlier financial round has not been processed.")
	var state: Variant = world.finance
	var descriptors: Array = []
	var club_ids: Array = world.clubs.keys()
	club_ids.sort()
	for club_id in club_ids:
		var club: Variant = world.clubs[club_id]
		var wages: int = _safe_payroll(world, club_id)
		if wages < 0 or wages > Config.LIMIT or club.capacity < 0 or club.capacity > 1000000000:
			return _failure("Invalid payroll/stadium capacity.")
		var maintenance: int = state.config_snapshot.maintenance_per_round[club.profile]
		descriptors.append(_descriptor(state, club_id, round_number, "WAGES", -wages, {"wages_per_round": wages}))
		descriptors.append(_descriptor(state, club_id, round_number, "MAINTENANCE", -maintenance, {"maintenance_per_round": maintenance}))
		for fixture in world.fixtures.values():
			if fixture.round != round_number or fixture.home_club_id != club_id:
				continue
			if fixture.status != "COMPLETED":
				return _failure("Matchday revenue requires a completed fixture.")
			var occupancy: int = state.config_snapshot.occupancy_basis_points[club.profile]
			var price: int = state.config_snapshot.ticket_price
			@warning_ignore("integer_division")
			var attendance: int = club.capacity * occupancy / 10000
			descriptors.append(_descriptor(state, club_id, round_number, "MATCHDAY_REVENUE", attendance * price, {"fixture_id": fixture.id, "capacity": club.capacity, "attendance": attendance, "ticket_price": price, "occupancy_basis_points": occupancy}))
	if state.processed_rounds.has(str(round_number)):
		for descriptor in descriptors:
			var existing: Variant = _find_key(state, descriptor.operation_key)
			if existing == null or existing.descriptor() != descriptor:
				return _failure("Conflicting financial operation payload.")
		return {"ok": true, "idempotent": true, "errors": PackedStringArray()}
	var candidate := _copy_state(state)
	candidate.processed_rounds[str(round_number)] = true
	return _commit(world, candidate, descriptors)

func apply_operation(world: Variant, descriptor: Dictionary) -> Dictionary:
	# An individual operation may be retried, but new entries are published only
	# as complete opening/round batches. This prevents partial financial rounds.
	if world == null or world.finance == null:
		return _failure("Finance is not initialized.")
	var errors: PackedStringArray = Validator.validate(world)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	var entry: Variant = _find_key(world.finance, descriptor.get("operation_key", ""))
	if entry == null:
		return _failure("New financial operations require an atomic complete batch.")
	if entry.descriptor() != descriptor:
		return _failure("Conflicting financial operation payload.")
	return {"ok": true, "idempotent": true, "errors": PackedStringArray()}

func ledger(world: Variant, club_id: String) -> Array:
	var values: Array = []
	if world == null or world.finance == null:
		return values
	for entry in world.finance.entries.values():
		if entry.club_id == club_id:
			values.append(entry.projection())
	values.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.round_number != b.round_number:
			return a.round_number < b.round_number
		return int(a.id.get_slice(":", a.id.get_slice_count(":") - 1)) < int(b.id.get_slice(":", b.id.get_slice_count(":") - 1)))
	return values

func balance(world: Variant, club_id: String) -> int:
	var total: int = 0
	for entry in ledger(world, club_id):
		total += entry.amount
	return total

func summary(world: Variant, club_id: String) -> Dictionary:
	var data := {"balance": balance(world, club_id), "income": 0, "expenses": 0, "net": 0, "payroll": 0, "wages": 0, "maintenance": 0, "matchday_revenue": 0, "categories": {"MATCHDAY_REVENUE": 0, "WAGES": 0, "MAINTENANCE": 0}}
	if world == null or world.finance == null or not world.clubs.has(club_id):
		return data
	data.payroll = world.payroll(club_id)
	for entry in ledger(world, club_id):
		if entry.category == "OPENING_BALANCE":
			continue
		data.categories[entry.category] += entry.amount
		if entry.amount > 0:
			data.income += entry.amount
		else:
			data.expenses -= entry.amount
		if entry.category == "WAGES":
			data.wages -= entry.amount
		elif entry.category == "MAINTENANCE":
			data.maintenance -= entry.amount
		elif entry.category == "MATCHDAY_REVENUE":
			data.matchday_revenue += entry.amount
	data.net = data.income - data.expenses
	return data

func _commit(world: Variant, state: Variant, descriptors: Array) -> Dictionary:
	var serial: int = world.career.next_entity_serial
	if serial < 1 or serial > 9223372036854775807 - descriptors.size():
		return _failure("Financial entity counter exhausted.")
	var balances := {}
	for club_id in world.clubs:
		balances[club_id] = 0
	for entry in state.entries.values():
		balances[entry.club_id] += entry.amount
	for descriptor in descriptors:
		if typeof(descriptor.amount) != TYPE_INT or descriptor.amount < -Config.LIMIT or descriptor.amount > Config.LIMIT:
			return _failure("Invalid integer financial amount.")
		var entry := Entry.new()
		entry.id = "%s:finance:%d" % [world.career.id, serial]
		serial += 1
		for field in descriptor:
			entry.set(field, descriptor[field].duplicate(true) if descriptor[field] is Dictionary else descriptor[field])
		state.entries[entry.id] = entry
		balances[entry.club_id] += entry.amount
	# A shallow validation view contains staged cash/counter only. The original
	# world, its counter and its clubs are unchanged until validation succeeds.
	var view: Variant = world.get_script().new()
	for field in ["players", "contracts", "leagues", "fixtures", "manager", "season"]:
		view.set(field, world.get(field))
	view.career = world.career.get_script().new()
	view.career.id = world.career.id
	view.career.next_entity_serial = serial
	for club_id in world.clubs:
		var club: Variant = world.clubs[club_id].get_script().new()
		club.id = club_id
		club.profile = world.clubs[club_id].profile
		club.cash = balances[club_id]
		view.clubs[club_id] = club
	view.finance = state
	var errors: PackedStringArray = Validator.validate(view)
	if not errors.is_empty():
		return {"ok": false, "errors": errors}
	world.finance = state
	world.career.next_entity_serial = serial
	for club_id in balances:
		world.clubs[club_id].cash = balances[club_id]
	return {"ok": true, "idempotent": false, "errors": PackedStringArray()}

func _descriptor(state: Variant, club_id: String, round_number: int, category: String, amount: int, context: Dictionary) -> Dictionary:
	var key: String = Validator.opening_key(state.season_id, club_id) if category == "OPENING_BALANCE" else Validator.operation_key(state.season_id, round_number, club_id, category)
	return {"club_id": club_id, "season_id": state.season_id, "round_number": round_number, "category": category, "amount": amount, "operation_key": key, "description_key": category, "context": context}

func _copy_state(state: Variant) -> RefCounted:
	var candidate := State.new()
	candidate.config_snapshot = state.config_snapshot.duplicate(true)
	candidate.season_id = state.season_id
	candidate.baseline_committed_round = state.baseline_committed_round
	candidate.processed_rounds = state.processed_rounds.duplicate(true)
	candidate.entries = state.entries.duplicate()
	return candidate

func _find_key(state: Variant, key: String) -> Variant:
	for entry in state.entries.values():
		if entry.operation_key == key:
			return entry
	return null

func _safe_payroll(world: Variant, club_id: String) -> int:
	var total: int = 0
	for contract in world.contracts.values():
		if not contract.active or contract.kind != "athlete" or contract.club_id != club_id:
			continue
		if contract.salary < 0 or contract.salary > Config.LIMIT - total:
			return -1
		total += contract.salary
	return total

func _failure(message: String) -> Dictionary:
	return {"ok": false, "errors": PackedStringArray([message])}
