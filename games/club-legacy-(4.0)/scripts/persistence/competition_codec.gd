extends RefCounted

const Season = preload("res://scripts/domain/models/season.gd")
const Fixture = preload("res://scripts/domain/models/fixture.gd")
const FIXTURE_FIELDS := {"id": "s", "season_id": "s", "league_id": "s", "round": "i", "home_club_id": "s", "away_club_id": "s", "status": "s", "home_goals": "i", "away_goals": "i", "result_operation_key": "s"}

func encode(world) -> Dictionary:
	var result := {"season": null, "fixtures": []}
	if world.season == null: return result
	var season = world.season
	result.season = {"id": season.id, "number": str(season.number), "status": season.status,
		"current_round": str(season.current_round), "members": season.members.duplicate(true),
		"tiebreak_order": season.tiebreak_order.duplicate(true), "round_states": season.round_states.duplicate(true),
		"operations": season.operations.duplicate(true)}
	var ids: Array = world.fixtures.keys()
	ids.sort()
	for id in ids:
		var fixture = world.fixtures[id]
		var record: Dictionary = {}
		for field in FIXTURE_FIELDS:
			record[field] = str(fixture.get(field)) if FIXTURE_FIELDS[field] == "i" else fixture.get(field)
		result.fixtures.append(record)
	return result

func decode(payload: Dictionary, world) -> PackedStringArray:
	var errors := PackedStringArray()
	if not payload.has("season") or not payload.get("fixtures") is Array or payload.fixtures.size() > 60:
		return PackedStringArray(["Missing/invalid competition payload."])
	if payload.season == null:
		return errors if payload.fixtures.is_empty() else PackedStringArray(["Fixtures without season."])
	if not payload.season is Dictionary: return PackedStringArray(["Invalid season type."])
	var record: Dictionary = payload.season
	var season = Season.new()
	for field in ["id", "status"]:
		if not record.get(field) is String: return PackedStringArray(["Invalid season string field."])
		season.set(field, record[field])
	for field in ["number", "current_round"]:
		if not _integer(record.get(field)): return PackedStringArray(["Invalid season integer field."])
		season.set(field, int(record[field]))
	for field in ["members", "tiebreak_order", "round_states", "operations"]:
		if not record.get(field) is Dictionary: return PackedStringArray(["Invalid season map field."])
		season.set(field, record[field].duplicate(true))
	for field in ["members", "tiebreak_order"]:
		for ids in record[field].values():
			if not ids is Array: return PackedStringArray(["Invalid division member list."])
			for id in ids:
				if not id is String: return PackedStringArray(["Invalid member ID type."])
	for value in season.round_states.values():
		if not value is String: return PackedStringArray(["Invalid round state type."])
	for operation in season.operations.values():
		if not operation is Dictionary: return PackedStringArray(["Invalid operation descriptor."])
		for value in operation.values():
			if not value is String: return PackedStringArray(["Invalid operation descriptor field."])
	world.season = season
	for entry in payload.fixtures:
		if not entry is Dictionary: return PackedStringArray(["Invalid fixture record."])
		var fixture = Fixture.new()
		for field in FIXTURE_FIELDS:
			var value = entry.get(field)
			if FIXTURE_FIELDS[field] == "i":
				if not _integer(value): return PackedStringArray(["Invalid fixture integer field."])
				value = int(value)
			elif not value is String:
				return PackedStringArray(["Invalid fixture string field."])
			fixture.set(field, value)
		if world.fixtures.has(fixture.id): return PackedStringArray(["Duplicate fixture ID."])
		world.fixtures[fixture.id] = fixture
	return errors

func _integer(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(int(value)) == value
