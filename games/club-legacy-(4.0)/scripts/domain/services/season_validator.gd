extends RefCounted

func validate(world) -> PackedStringArray:
	var errors := PackedStringArray()
	if world.season == null:
		if not world.fixtures.is_empty():
			errors.append("Fixtures require a season.")
		return errors
	var season = world.season
	if season.number != 1 or season.status not in ["READY", "RESOLVING", "AWAITING_COMPLETION", "COMPLETED"] or season.current_round < 1 or season.current_round > 10:
		errors.append("Invalid current season phase/round.")
	if not _valid_id(season.id, world.career) or world.fixtures.size() != 60:
		errors.append("Invalid season ID or fixture count.")
	var all_ids: Dictionary = {world.career.id: true, world.manager.id: true}
	for collection in [world.clubs, world.players, world.contracts, world.leagues]:
		for id in collection:
			all_ids[id] = true
	if all_ids.has(season.id):
		errors.append("Season ID collision.")
	all_ids[season.id] = true
	if season.members.size() != 2 or season.tiebreak_order.size() != 2 or season.round_states.size() != 10:
		errors.append("Invalid frozen divisions/draw/round states.")
	var matches: Dictionary = {}
	var pair_counts: Dictionary = {}
	var result_keys: Dictionary = {}
	for league_id in world.leagues:
		if not season.members.has(league_id) or not season.tiebreak_order.has(league_id):
			errors.append("Missing season league snapshot.")
			continue
		var members: Array = season.members[league_id]
		var order: Array = season.tiebreak_order[league_id]
		var unique: Dictionary = {}
		for club_id in members:
			if not world.clubs.has(club_id) or world.clubs[club_id].league_id != league_id or unique.has(club_id):
				errors.append("Invalid/duplicate member or wrong division.")
			unique[club_id] = true
		var sorted_members: Array = members.duplicate()
		var sorted_order: Array = order.duplicate()
		sorted_members.sort()
		sorted_order.sort()
		if members.size() != 6 or sorted_members != sorted_order:
			errors.append("Tie order must be a permutation of six members.")
	for id in world.fixtures:
		var fixture = world.fixtures[id]
		if id != fixture.id or all_ids.has(id) or not _valid_id(id, world.career):
			errors.append("Invalid/duplicate fixture ID.")
		all_ids[id] = true
		if fixture.season_id != season.id or fixture.round < 1 or fixture.round > 10 or not season.members.has(fixture.league_id):
			errors.append("Fixture season/round/league invalid.")
			continue
		var members: Array = season.members[fixture.league_id]
		if fixture.home_club_id == fixture.away_club_id or fixture.home_club_id not in members or fixture.away_club_id not in members:
			errors.append("Fixture clubs invalid or wrong division.")
		var round_key: String = fixture.league_id + ":" + str(fixture.round)
		if not matches.has(round_key):
			matches[round_key] = []
		matches[round_key].append(fixture)
		var pair: String = fixture.home_club_id + "|" + fixture.away_club_id
		pair_counts[pair] = pair_counts.get(pair, 0) + 1
		if fixture.status == "COMPLETED":
			if fixture.home_goals < 0 or fixture.away_goals < 0 or fixture.home_goals > 1000 or fixture.away_goals > 1000 or fixture.result_operation_key.is_empty() or result_keys.has(fixture.result_operation_key):
				errors.append("Invalid completed result or operation key.")
			result_keys[fixture.result_operation_key] = true
			var descriptor := {"kind": "result", "fixture_id": id, "home": str(fixture.home_goals), "away": str(fixture.away_goals)}
			if season.operations.get(fixture.result_operation_key) != descriptor:
				errors.append("Result operation inconsistent.")
		else:
			if fixture.status not in ["PENDING", "ACTIVE"] or fixture.home_goals != -1 or fixture.away_goals != -1 or not fixture.result_operation_key.is_empty():
				errors.append("Invalid uncompleted fixture.")
		if fixture.round > season.current_round and fixture.status != "PENDING":
			errors.append("Future fixture cannot be processed.")
	for league_id in world.leagues:
		for round_number in range(1, 11):
			var group: Array = matches.get(league_id + ":" + str(round_number), [])
			var played: Dictionary = {}
			for fixture in group:
				played[fixture.home_club_id] = true
				played[fixture.away_club_id] = true
			if group.size() != 3 or played.size() != 6:
				errors.append("Round requires three fixtures and six distinct clubs per league.")
		for home in season.members.get(league_id, []):
			for away in season.members.get(league_id, []):
				if home != away and pair_counts.get(home + "|" + away, 0) != 1:
					errors.append("Each directed pair must appear exactly once.")
	for round_number in range(1, 11):
		var state = season.round_states.get(str(round_number))
		var completed: int = 0
		var active: int = 0
		for fixture in world.fixtures.values():
			if fixture.round == round_number:
				if fixture.status == "COMPLETED": completed += 1
				if fixture.status == "ACTIVE": active += 1
		if state not in ["READY", "RESOLVING", "COMMITTED"]:
			errors.append("Invalid round state.")
		if state == "COMMITTED" and completed != 6:
			errors.append("Committed round must have six results.")
		if state == "READY" and (completed != 0 or active != 0):
			errors.append("Ready round has processed fixtures.")
		if state == "RESOLVING" and completed == 0 and active == 0:
			errors.append("Resolving round has no started fixture.")
		if round_number < season.current_round and state != "COMMITTED":
			errors.append("Previous rounds must be committed.")
		if round_number > season.current_round and state != "READY":
			errors.append("Future rounds must be ready.")
		if state == "COMMITTED" and not _has_operation(season.operations, {"kind": "round", "round": str(round_number)}):
			errors.append("Missing round commit key.")
	if season.status in ["AWAITING_COMPLETION", "COMPLETED"]:
		for state in season.round_states.values():
			if state != "COMMITTED": errors.append("Season cannot finish before all commits.")
		if season.status == "COMPLETED" and not _has_operation(season.operations, {"kind": "finish", "season_id": season.id}):
			errors.append("Missing season completion key.")
	elif season.status == "READY" and season.round_states.get(str(season.current_round)) != "READY":
		errors.append("Season phase inconsistent with current round.")
	elif season.status == "RESOLVING" and season.round_states.get(str(season.current_round)) != "RESOLVING":
		errors.append("Season phase inconsistent with current round.")
	for key in season.operations:
		if not key is String or key.strip_edges().is_empty() or key.length() > 256 or not season.operations[key] is Dictionary:
			errors.append("Invalid operation record.")
			continue
		var operation: Dictionary = season.operations[key]
		if operation.get("kind") == "result":
			if not result_keys.has(key): errors.append("Orphan result operation.")
		elif operation.get("kind") == "round":
			if operation.get("round") not in season.round_states or season.round_states.get(operation.get("round")) != "COMMITTED": errors.append("Orphan round operation.")
		elif operation.get("kind") == "finish":
			if season.status != "COMPLETED" or operation.get("season_id") != season.id: errors.append("Orphan finish operation.")
		else:
			errors.append("Unknown operation kind.")
	return errors

func _has_operation(operations: Dictionary, expected: Dictionary) -> bool:
	var count: int = 0
	for operation in operations.values():
		if operation == expected: count += 1
	return count == 1

func _valid_id(id: String, career) -> bool:
	if not id.begins_with(career.id + ":"):
		return false
	var serial: String = id.get_slice(":", id.get_slice_count(":") - 1)
	return serial.is_valid_int() and str(int(serial)) == serial and int(serial) > 0 and int(serial) < career.next_entity_serial
