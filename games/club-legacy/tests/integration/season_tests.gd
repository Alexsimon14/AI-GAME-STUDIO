extends RefCounted

const Factory = preload("res://scripts/domain/services/world_factory.gd")
const Config = preload("res://resources/config/world_config.tres")
const Service = preload("res://scripts/domain/services/season_service.gd")
const Table = preload("res://scripts/domain/services/table_calculator.gd")
const Codec = preload("res://scripts/persistence/world_codec.gd")
const Envelope = preload("res://scripts/persistence/save_envelope.gd")
const Repository = preload("res://scripts/persistence/save_repository.gd")
const WorldTests = preload("res://tests/unit/world_model_tests.gd")

func _new_world():
	return Factory.new().create(Config, 314159, "Treinador", "MEDIO", "season-test").world

func run(check: Callable) -> void:
	var service = Service.new()
	var table = Table.new()
	var world = _new_world()
	check.call(service.create(world).errors.is_empty(), "Phase 3 creates valid Season")
	check.call(world.fixtures.size() == 60, "60 fixtures per season")
	check.call(world.season.round_states.size() == 10, "Ten world rounds")
	for league_id in world.leagues:
		var count: int = 0
		for fixture in world.fixtures.values():
			if fixture.league_id == league_id: count += 1
		check.call(count == 30, "30 fixtures per division: " + league_id)
		for round_number in range(1, 11):
			var seen: Dictionary = {}
			var fixtures: Array = _round(world, round_number, league_id)
			for fixture in fixtures:
				seen[fixture.home_club_id] = true
				seen[fixture.away_club_id] = true
			check.call(fixtures.size() == 3 and seen.size() == 6, "Three games/six unique clubs per division-round " + str(round_number))
	for club_id in world.clubs:
		var home: int = 0
		var away: int = 0
		var opponents: Dictionary = {}
		for fixture in world.fixtures.values():
			if fixture.home_club_id == club_id:
				home += 1
				opponents[fixture.away_club_id] = opponents.get(fixture.away_club_id, 0) + 1
			if fixture.away_club_id == club_id:
				away += 1
				opponents[fixture.home_club_id] = opponents.get(fixture.home_club_id, 0) + 1
		check.call(home == 5 and away == 5 and opponents.size() == 5 and opponents.values().all(func(count): return count == 2), "Ten matches/home-away against five opponents: " + club_id)
	var duplicate_world = _new_world()
	service.create(duplicate_world)
	check.call(Codec.new().encode(world).payload == Codec.new().encode(duplicate_world).payload, "Deterministic calendar and preseason tiebreak draw")
	check.call(not service.create(world).errors.is_empty(), "Duplicate calendar creation rejected")
	var first = _round(world, 1)[0]
	check.call(not service.submit_result(world, "missing", 1, 0, "missing").errors.is_empty(), "Unknown fixture rejected")
	check.call(not service.submit_result(world, first.id, -1, 0, "negative").errors.is_empty(), "Negative result rejected")
	check.call(not service.submit_result(world, first.id, 1.5, 0, "fraction").errors.is_empty(), "Fractional score rejected")
	check.call(not service.submit_result(world, first.id, 1, 0, " ").errors.is_empty(), "Empty operation key rejected")
	check.call(not service.commit_round(world, 0, "bad-round").errors.is_empty(), "Invalid round rejected")
	check.call(not service.commit_round(world, 1, "early").errors.is_empty(), "Incomplete round cannot advance")
	check.call(not service.finish(world, "early-finish").errors.is_empty(), "Incomplete season cannot finish")
	check.call(not service.submit_result(world, _round(world, 2)[0].id, 1, 0, "future-fixture").errors.is_empty(), "Future round result rejected")
	check.call(service.submit_result(world, first.id, 2, 1, "result-first").errors.is_empty(), "External controlled win accepted")
	var before_table: Array = table.calculate(world, first.league_id)
	check.call(service.submit_result(world, first.id, 2, 1, "result-first").idempotent and table.calculate(world, first.league_id) == before_table, "Same result/key idempotent without duplicated points")
	check.call(not service.submit_result(world, first.id, 3, 0, "result-first").errors.is_empty(), "Conflicting payload for result key rejected")
	check.call(not service.submit_result(world, first.id, 2, 1, "different-key").errors.is_empty(), "Completed fixture rejects another operation")
	check.call(not service.submit_result(world, _round(world, 1)[1].id, 2, 1, "result-first").errors.is_empty(), "Operation key cannot be reused for another fixture")
	var home_row: Dictionary = _row(before_table, first.home_club_id)
	var away_row: Dictionary = _row(before_table, first.away_club_id)
	check.call(home_row.played == 1 and home_row.wins == 1 and home_row.points == 3 and home_row.goals_for == 2 and home_row.goals_against == 1 and home_row.goal_difference == 1, "Win points/goals/difference correct")
	check.call(away_row.played == 1 and away_row.losses == 1 and away_row.points == 0 and away_row.goal_difference == -1, "Loss points/goals/difference correct")
	var other = _round(world, 1, first.league_id)[1]
	service.submit_result(world, other.id, 1, 1, "draw-first")
	var draw_row: Dictionary = _row(table.calculate(world, first.league_id), other.home_club_id)
	check.call(draw_row.draws == 1 and draw_row.points == 1 and draw_row.goals_for == 1 and draw_row.goals_against == 1 and draw_row.goal_difference == 0, "Draw gives one point and coherent goals")
	var frozen: Dictionary = Codec.new().encode(world).payload
	for _read in range(5): table.calculate(world, first.league_id)
	check.call(Codec.new().encode(world).payload == frozen, "Table reads do not mutate state or RNG")
	for metric in ["points", "goal_difference", "goals_for", "wins"]:
		var a := {"club_id": "a", "points": 10, "goal_difference": 3, "goals_for": 8, "wins": 2}
		var b: Dictionary = a.duplicate()
		b.club_id = "b"
		a[metric] += 1
		check.call(table.precedes(a, b, ["b", "a"]), "GDD tiebreak criterion precedes draw: " + metric)
	var tied := {"club_id": "a", "points": 10, "goal_difference": 3, "goals_for": 8, "wins": 2}
	var tied_b: Dictionary = tied.duplicate()
	tied_b.club_id = "b"
	check.call(table.precedes(tied_b, tied, ["b", "a"]), "Absolute tie uses preseason order, not club name")
	# Corruption validators, restoring original fields after each scenario.
	var original_home: String = first.home_club_id
	first.home_club_id = first.away_club_id
	check.call(not world.validation_errors().is_empty(), "Self fixture rejected")
	first.home_club_id = "missing"
	check.call(not world.validation_errors().is_empty(), "Invalid club reference rejected")
	first.home_club_id = _other_division_club(world, first.league_id)
	check.call(not world.validation_errors().is_empty(), "Fixture from wrong division rejected")
	first.home_club_id = original_home
	var second_fixture = _round(world, 1, first.league_id)[1]
	var second_home: String = second_fixture.home_club_id
	second_fixture.home_club_id = original_home
	check.call(not world.validation_errors().is_empty(), "Club playing twice in round rejected")
	second_fixture.home_club_id = second_home
	var root_path: String = "user://phase3_tests_" + str(Time.get_ticks_usec())
	var repository = Repository.new(root_path)
	# Save partial round, release state, reload and retry same operation.
	world = _checkpoint(world, repository, check, "partial first round")
	check.call(service.submit_result(world, first.id, 2, 1, "result-first").idempotent, "Result retry after load is idempotent")
	for round_number in range(1, 11):
		for fixture in _round(world, round_number):
			if fixture.status != "COMPLETED":
				check.call(service.submit_result(world, fixture.id, 0, 0, "score:" + fixture.id).errors.is_empty(), "Controlled score accepted: " + fixture.id)
		if round_number == 10:
			world = _checkpoint(world, repository, check, "all results before last commit")
			check.call(not service.finish(world, "too-soon").errors.is_empty(), "All results insufficient until last round committed")
		check.call(service.commit_round(world, round_number, "close:" + str(round_number)).errors.is_empty(), "Commit world round " + str(round_number))
		var progress: int = world.season.current_round
		check.call(service.commit_round(world, round_number, "close:" + str(round_number)).idempotent and world.season.current_round == progress, "Round commit retry cannot advance again " + str(round_number))
		check.call(not service.commit_round(world, round_number, "other-close:" + str(round_number)).errors.is_empty(), "Round cannot recommit under another key " + str(round_number))
		if round_number in [1, 5, 9]: world = _checkpoint(world, repository, check, "after round " + str(round_number))
	check.call(service.finish(world, "season-finish").errors.is_empty() and world.season.status == "COMPLETED", "Season completes only after sixty results and ten commits")
	check.call(service.finish(world, "season-finish").idempotent, "Season completion idempotent")
	check.call(world.validation_errors().is_empty(), "Completed season invariants valid")
	var outcomes: Dictionary = service.outcomes(world)
	check.call(not outcomes.promotion_club_id.is_empty() and not outcomes.relegation_club_id.is_empty(), "Promotion/relegation determined")
	for league in world.leagues.values():
		var final_table: Array = table.calculate(world, league.id)
		check.call(final_table.size() == 6 and final_table.all(func(row): return row.played == 10), "Final table has six clubs with ten games")
		if league.tier == 1: check.call(outcomes.relegation_club_id == final_table[5].club_id, "Last division I club relegation candidate")
		else: check.call(outcomes.promotion_club_id == final_table[0].club_id, "First division II club promotion candidate")
	check.call(world.clubs[outcomes.promotion_club_id].league_id != world.clubs[outcomes.relegation_club_id].league_id, "No actual division transition performed")
	world = _checkpoint(world, repository, check, "completed season")
	check.call(service.outcomes(world) == outcomes and service.finish(world, "season-finish").idempotent, "Completion/outcomes/retry survive final load")
	var codec = Codec.new()
	var payload: Dictionary = codec.encode(world).payload
	for variant in ["season", "fixture", "operation", "missing"]:
		var broken: Dictionary = payload.duplicate(true)
		match variant:
			"season": broken.season.current_round = "20"
			"fixture": broken.fixtures[0].home_club_id = "missing"
			"operation": broken.season.operations.clear()
			"missing": broken.erase("fixtures")
		check.call(codec.decode(broken).world == null, "Corrupt competition payload rejected: " + variant)
	# Historical schema 1 fixture: exact Phase 2 envelope/payload shape.
	var old_world = _new_world()
	var old_state: Dictionary = WorldTests.new().structure(old_world)
	var legacy_payload: Dictionary = codec.encode(old_world).payload
	legacy_payload.erase("season")
	legacy_payload.erase("fixtures")
	var envelope = Envelope.new()
	var legacy := {"schema_version": 1, "save_version": "phase-2-v1", "engine_version": "4.7.2.stable.official.ed1daf0bf", "revision": "7", "payload": legacy_payload}
	legacy.checksum = envelope.checksum(legacy)
	var migrated: Dictionary = envelope.unpack(JSON.stringify(legacy))
	check.call(migrated.errors.is_empty() and migrated.migrated and migrated.revision == 7, "Real migration schema 1 -> 2 preserves revision")
	if migrated.world != null:
		var restored_state: Dictionary = WorldTests.new().structure(migrated.world)
		var old_counter: int = old_state.career.next_entity_serial
		restored_state.career.next_entity_serial = old_counter
		check.call(restored_state == old_state, "Migration preserves old entities/IDs/contracts/config; counter only advances for new IDs")
		check.call(migrated.world.season.current_round == 1 and migrated.world.season.status == "READY" and migrated.world.fixtures.values().all(func(f): return f.status == "PENDING"), "Migration creates unplayed first season without invented progress")
		check.call(envelope.unpack(JSON.stringify(legacy)).world.season.tiebreak_order == migrated.world.season.tiebreak_order, "Migration deterministic on repeated load")
		check.call(envelope.unpack(envelope.pack(migrated.world, 8).text).errors.is_empty(), "Migrated world persists as schema 2")
	var incomplete_legacy: Dictionary = legacy.duplicate(true)
	incomplete_legacy.payload.contracts[0].club_id = "missing"
	incomplete_legacy.checksum = envelope.checksum(incomplete_legacy)
	check.call(envelope.unpack(JSON.stringify(incomplete_legacy)).world == null, "Corrupt legacy world rejected before migration")
	# Fresh state start checkpoint, then A/B historical migration without touching original file.
	var initial = _new_world()
	service.create(initial)
	initial = _checkpoint(initial, repository, check, "initial unplayed season")
	_cleanup(root_path)
	DirAccess.make_dir_recursive_absolute(root_path)
	_write(root_path.path_join("a.json"), JSON.stringify(legacy))
	var legacy_repository = Repository.new(root_path)
	var migrated_load: Dictionary = legacy_repository.load_world()
	check.call(migrated_load.errors.is_empty() and migrated_load.migrated, "Repository loads schema 1 through migration")
	check.call(FileAccess.get_file_as_string(root_path.path_join("a.json")) == JSON.stringify(legacy), "Migration load leaves original snapshot untouched")
	check.call(legacy_repository.save_world(migrated_load.world).revision == 8, "Commit migrated schema 2 advances revision and keeps previous A")
	_cleanup(root_path)
	check.call(not DirAccess.dir_exists_absolute(root_path), "Phase 3 isolated test files cleaned")

func _round(world, number: int, league_id: String = "") -> Array:
	var fixtures: Array = []
	for fixture in world.fixtures.values():
		if fixture.round == number and (league_id.is_empty() or fixture.league_id == league_id): fixtures.append(fixture)
	fixtures.sort_custom(func(a, b): return a.id < b.id)
	return fixtures

func _row(rows: Array, club_id: String) -> Dictionary:
	for row in rows:
		if row.club_id == club_id: return row
	return {}

func _other_division_club(world, league_id: String) -> String:
	for club in world.clubs.values():
		if club.league_id != league_id: return club.id
	return ""

func _checkpoint(world, repository, check: Callable, label: String):
	var codec = Codec.new()
	var expected: Dictionary = codec.encode(world).payload
	var saved: Dictionary = repository.save_world(world)
	world = null
	var loaded: Dictionary = repository.load_world()
	check.call(saved.errors.is_empty() and loaded.errors.is_empty() and codec.encode(loaded.world).payload == expected, "Exact save/release/load checkpoint: " + label)
	return loaded.world

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _cleanup(path: String) -> void:
	for name in ["a.json", "b.json", "snapshot.tmp"]:
		if FileAccess.file_exists(path.path_join(name)): DirAccess.remove_absolute(path.path_join(name))
	DirAccess.remove_absolute(path)
