extends RefCounted
## Competition commands only. External scores are never generated here.

const SeasonModel = preload("res://scripts/domain/models/season.gd")
const FixtureModel = preload("res://scripts/domain/models/fixture.gd")
const Table = preload("res://scripts/domain/services/table_calculator.gd")

func create(world) -> Dictionary:
	if world.season != null or not world.fixtures.is_empty():
		return _error("Season already exists; refusing duplicate calendar.")
	if not world.validation_errors().is_empty():
		return _error("Invalid world for competition.")
	var season = SeasonModel.new()
	season.id = world.career.allocate_id("season")
	var rng := RandomNumberGenerator.new()
	rng.seed = world.career.seed
	var league_ids: Array = world.leagues.keys()
	league_ids.sort()
	for league_id in league_ids:
		var members: Array = []
		for club in world.clubs.values():
			if club.league_id == league_id: members.append(club.id)
		members.sort()
		season.members[league_id] = members.duplicate()
		var drawn: Array = members.duplicate()
		for index in range(drawn.size() - 1, 0, -1):
			var other: int = rng.randi_range(0, index)
			var value = drawn[index]
			drawn[index] = drawn[other]
			drawn[other] = value
		season.tiebreak_order[league_id] = drawn
		var ring: Array = members.duplicate()
		for first_round in range(5):
			for pair in range(3):
				var home: String = ring[pair]
				var away: String = ring[5 - pair]
				if (first_round + pair) % 2 == 1:
					var swap: String = home
					home = away
					away = swap
				_add_fixture(world, season, league_id, first_round + 1, home, away)
				_add_fixture(world, season, league_id, first_round + 6, away, home)
			ring.insert(1, ring.pop_back())
	for round_number in range(1, 11):
		season.round_states[str(round_number)] = "READY"
	world.season = season
	return {"errors": world.validation_errors(), "idempotent": false}

func _add_fixture(world, season, league_id: String, round_number: int, home: String, away: String) -> void:
	var fixture = FixtureModel.new()
	fixture.id = world.career.allocate_id("fixture")
	fixture.season_id = season.id
	fixture.league_id = league_id
	fixture.round = round_number
	fixture.home_club_id = home
	fixture.away_club_id = away
	world.fixtures[fixture.id] = fixture

func submit_result(world, fixture_id: String, home: Variant, away: Variant, operation_key: String) -> Dictionary:
	if not _valid_key(operation_key) or not home is int or not away is int or home < 0 or away < 0 or home > 1000 or away > 1000:
		return _error("Invalid external result or operation key.")
	if world.season == null or not world.fixtures.has(fixture_id):
		return _error("Fixture does not exist.")
	if not world.validation_errors().is_empty():
		return _error("Competition state is invalid.")
	var descriptor := {"kind": "result", "fixture_id": fixture_id, "home": str(home), "away": str(away)}
	var replay: Dictionary = _replay(world.season, operation_key, descriptor)
	if not replay.is_empty(): return replay
	var fixture = world.fixtures[fixture_id]
	if fixture.status == "COMPLETED":
		return _error("Fixture result is immutable; operation does not match original.")
	if fixture.round != world.season.current_round or world.season.status == "COMPLETED" or world.season.round_states[str(fixture.round)] == "COMMITTED":
		return _error("Result outside current uncommitted round.")
	fixture.status = "ACTIVE"
	fixture.home_goals = home
	fixture.away_goals = away
	fixture.result_operation_key = operation_key
	fixture.status = "COMPLETED"
	world.season.operations[operation_key] = descriptor
	world.season.round_states[str(fixture.round)] = "RESOLVING"
	world.season.status = "RESOLVING"
	return {"errors": PackedStringArray(), "idempotent": false}

func commit_round(world, round_number: int, operation_key: String) -> Dictionary:
	if world.season == null or round_number < 1 or round_number > 10 or not _valid_key(operation_key):
		return _error("Invalid round or operation key.")
	if not world.validation_errors().is_empty(): return _error("Invalid competition state.")
	var descriptor := {"kind": "round", "round": str(round_number)}
	var replay: Dictionary = _replay(world.season, operation_key, descriptor)
	if not replay.is_empty(): return replay
	if round_number != world.season.current_round or world.season.round_states[str(round_number)] == "COMMITTED":
		return _error("Round is not current or already committed by another operation.")
	for fixture in world.fixtures.values():
		if fixture.round == round_number and fixture.status != "COMPLETED":
			return _error("Round has unfinished mandatory fixtures.")
	world.season.operations[operation_key] = descriptor
	world.season.round_states[str(round_number)] = "COMMITTED"
	if round_number < 10:
		world.season.current_round += 1
		world.season.status = "READY"
	else:
		world.season.status = "AWAITING_COMPLETION"
	return {"errors": PackedStringArray(), "idempotent": false}

func finish(world, operation_key: String) -> Dictionary:
	if world.season == null or not _valid_key(operation_key): return _error("Invalid completion command.")
	if not world.validation_errors().is_empty(): return _error("Invalid competition state.")
	var descriptor := {"kind": "finish", "season_id": world.season.id}
	var replay: Dictionary = _replay(world.season, operation_key, descriptor)
	if not replay.is_empty(): return replay
	if world.season.status != "AWAITING_COMPLETION": return _error("Season cannot finish before all round commits.")
	world.season.operations[operation_key] = descriptor
	world.season.status = "COMPLETED"
	return {"errors": PackedStringArray(), "idempotent": false}

func outcomes(world) -> Dictionary:
	if world.season == null or world.season.status != "COMPLETED" or not world.validation_errors().is_empty():
		return {"promotion_club_id": "", "relegation_club_id": ""}
	var divisions: Dictionary = {}
	for league in world.leagues.values(): divisions[league.tier] = league.id
	var table = Table.new()
	return {"promotion_club_id": table.calculate(world, divisions[2])[0].club_id,
		"relegation_club_id": table.calculate(world, divisions[1])[5].club_id}

func _replay(season, key: String, descriptor: Dictionary) -> Dictionary:
	if not season.operations.has(key): return {}
	if season.operations[key] != descriptor: return _error("Operation key reused with conflicting payload.")
	return {"errors": PackedStringArray(), "idempotent": true}

func _valid_key(key: String) -> bool:
	return not key.strip_edges().is_empty() and key.length() <= 256

func _error(reason: String) -> Dictionary:
	return {"errors": PackedStringArray([reason]), "idempotent": false}
