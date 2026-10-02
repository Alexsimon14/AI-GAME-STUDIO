extends RefCounted
const Config = preload("res://resources/config/finance_config.gd")
const Entry = preload("res://scripts/domain/finance/financial_entry.gd")
const State = preload("res://scripts/domain/finance/finance_state.gd")
const CATEGORIES = ["OPENING_BALANCE", "MATCHDAY_REVENUE", "WAGES", "MAINTENANCE"]

static func validate(world: Variant) -> PackedStringArray:
	if world.finance == null:
		return PackedStringArray()
	if not world.finance is State:
		return PackedStringArray(["Invalid financial state model."])
	var state: Variant = world.finance
	var errors := Config.validate_snapshot(state.config_snapshot)
	if not errors.is_empty():
		return errors
	for club in world.clubs.values():
		if not state.config_snapshot.maintenance_per_round.has(club.profile):
			return PackedStringArray(["Unknown financial club profile."])
	if world.season == null or state.season_id != world.season.id:
		return PackedStringArray(["Finance season reference invalid."])
	if state.baseline_committed_round < 0 or state.baseline_committed_round > 10:
		return PackedStringArray(["Invalid finance baseline."])
	for round_number in range(1, state.baseline_committed_round + 1):
		if world.season.round_states.get(str(round_number)) != "COMMITTED":
			errors.append("Finance baseline exceeds committed competition.")
	var keys := {}
	var balances := {}
	var openings := {}
	var round_counts := {}
	var occupied_ids := {}
	for group in [world.clubs, world.players, world.contracts, world.leagues, world.fixtures]:
		for entity_id in group:
			occupied_ids[entity_id] = true
	occupied_ids[world.career.id] = true
	occupied_ids[world.manager.id] = true
	occupied_ids[world.season.id] = true
	for key in state.entries:
		var entry: Variant = state.entries[key]
		if not entry is Entry:
			errors.append("Invalid financial entry model.")
			continue
		if key != entry.id or occupied_ids.has(entry.id):
			errors.append("Duplicate/inconsistent financial ID.")
		occupied_ids[entry.id] = true
		var prefix: String = world.career.id + ":finance:"
		var serial: String = entry.id.trim_prefix(prefix)
		if not entry.id.begins_with(prefix) or not serial.is_valid_int() or str(int(serial)) != serial or int(serial) < 1 or int(serial) >= world.career.next_entity_serial:
			errors.append("Invalid financial ID/counter.")
		if not world.clubs.has(entry.club_id) or entry.season_id != state.season_id:
			errors.append("Invalid financial club/season reference.")
			continue
		if entry.operation_key.is_empty() or keys.has(entry.operation_key):
			errors.append("Duplicate/empty financial operation key.")
		keys[entry.operation_key] = true
		if entry.category not in CATEGORIES or entry.description_key != entry.category:
			errors.append("Unknown financial category/description.")
		if entry.amount < -Config.LIMIT or entry.amount > Config.LIMIT:
			errors.append("Financial amount outside integrity limit.")
			continue
		balances[entry.club_id] = balances.get(entry.club_id, 0) + entry.amount
		if abs(balances[entry.club_id]) > Config.LIMIT:
			errors.append("Financial balance outside integrity limit.")
		if entry.category == "OPENING_BALANCE":
			if entry.round_number != state.baseline_committed_round or entry.amount < 0 or typeof(entry.context.get("baseline_committed_round")) != TYPE_INT or entry.context != {"baseline_committed_round": state.baseline_committed_round} or entry.operation_key != opening_key(state.season_id, entry.club_id):
				errors.append("Invalid opening balance.")
			openings[entry.club_id] = openings.get(entry.club_id, 0) + 1
			continue
		var round_key: String = str(entry.round_number)
		if entry.round_number <= state.baseline_committed_round or entry.round_number > 10 or state.processed_rounds.get(round_key) != true or world.season.round_states.get(round_key) != "COMMITTED":
			errors.append("Financial entry outside processed committed rounds.")
		if entry.operation_key != operation_key(state.season_id, entry.round_number, entry.club_id, entry.category):
			errors.append("Inconsistent financial operation key.")
		var group_key: String = round_key + "/" + entry.club_id + "/" + entry.category
		round_counts[group_key] = round_counts.get(group_key, 0) + 1
		_validate_context(world, state, entry, errors)
	for club_id in world.clubs:
		if openings.get(club_id, 0) != 1:
			errors.append("Club must have exactly one opening balance.")
		if balances.get(club_id, 0) != world.clubs[club_id].cash:
			errors.append("Cash does not reconcile with financial ledger.")
	for round_key in state.processed_rounds:
		if not round_key is String or not round_key.is_valid_int() or str(int(round_key)) != round_key or int(round_key) <= state.baseline_committed_round or int(round_key) > 10 or state.processed_rounds[round_key] != true or world.season.round_states.get(round_key) != "COMMITTED":
			errors.append("Invalid financial round marker.")
			continue
		for predecessor in range(state.baseline_committed_round + 1, int(round_key)):
			if state.processed_rounds.get(str(predecessor)) != true:
				errors.append("Non-contiguous financial round markers.")
		for club_id in world.clubs:
			for category in ["WAGES", "MAINTENANCE"]:
				if round_counts.get(round_key + "/" + club_id + "/" + category, 0) != 1:
					errors.append("Incomplete financial round expenses.")
			var home := false
			for fixture in world.fixtures.values():
				if fixture.round == int(round_key) and fixture.home_club_id == club_id:
					home = true
			if round_counts.get(round_key + "/" + club_id + "/MATCHDAY_REVENUE", 0) != (1 if home else 0):
				errors.append("Missing/invalid matchday revenue.")
	return errors

static func opening_key(season_id: String, club_id: String) -> String:
	return season_id + ":club:" + club_id + ":OPENING_BALANCE"

static func operation_key(season_id: String, round_number: int, club_id: String, category: String) -> String:
	return "%s:round:%d:club:%s:%s" % [season_id, round_number, club_id, category]

static func _validate_context(world: Variant, state: Variant, entry: Variant, errors: PackedStringArray) -> void:
	var context: Dictionary = entry.context
	var profile: String = world.clubs[entry.club_id].profile
	if entry.category == "WAGES":
		if context.keys().size() != 1 or typeof(context.get("wages_per_round")) != TYPE_INT or context.get("wages_per_round", -1) < 0 or context.get("wages_per_round", 0) > Config.LIMIT or entry.amount != -context.get("wages_per_round", 0):
			errors.append("Invalid wages snapshot/sign.")
	elif entry.category == "MAINTENANCE":
		var maintenance: int = state.config_snapshot.maintenance_per_round[profile]
		if typeof(context.get("maintenance_per_round")) != TYPE_INT or context != {"maintenance_per_round": maintenance} or entry.amount != -maintenance:
			errors.append("Invalid maintenance snapshot/sign.")
	elif entry.category == "MATCHDAY_REVENUE":
		if context.keys().size() != 5:
			errors.append("Invalid matchday context.")
			return
		for field in ["capacity", "attendance", "ticket_price", "occupancy_basis_points"]:
			if typeof(context.get(field)) != TYPE_INT:
				errors.append("Invalid matchday integer context.")
				return
		var fixture: Variant = world.fixtures.get(context.get("fixture_id"))
		var capacity: int = context.capacity
		var price: int = state.config_snapshot.ticket_price
		var occupancy: int = state.config_snapshot.occupancy_basis_points[profile]
		if fixture == null or fixture.status != "COMPLETED" or fixture.round != entry.round_number or fixture.home_club_id != entry.club_id or capacity < 0 or capacity > 1000000000 or context.ticket_price != price or context.occupancy_basis_points != occupancy:
			errors.append("Invalid matchday fixture/configuration reference.")
			return
		@warning_ignore("integer_division")
		var attendance: int = capacity * occupancy / 10000
		if context.attendance != attendance or attendance < 0 or attendance > capacity or entry.amount != attendance * price:
			errors.append("Invalid attendance/revenue calculation.")
