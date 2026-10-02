extends RefCounted
## Private, detached snapshot. Accessors return copies; no live Player/Club references.
const ENGINE_VERSION: int = 1
const FORMATIONS = {"4-4-2": {"GK": 1, "DEF": 4, "MID": 4, "ATT": 2}, "4-3-3": {"GK": 1, "DEF": 4, "MID": 3, "ATT": 3}, "5-3-2": {"GK": 1, "DEF": 5, "MID": 3, "ATT": 2}}
const TACTICS = ["CAUTELOSA", "EQUILIBRADA", "OFENSIVA"]
var _snapshot: Dictionary = {}

static func defaults() -> Dictionary:
	return {"version": "phase-4-test-v1", "purpose": "TEST / PLACEHOLDER", "home_initiative": 0.025, "fatigue_per_minute": 0.18, "opportunity_rate": 0.26}

func configure(data: Dictionary) -> PackedStringArray:
	var errors := validate(data)
	if errors.is_empty() and _snapshot.is_empty():
		_snapshot = data.duplicate(true)
		_snapshot.engine_version = ENGINE_VERSION
		for side in ["home", "away"]:
			for player in _snapshot[side].players.values():
				player.overall = float(player.overall)
				player.condition = float(player.condition)
	elif not _snapshot.is_empty():
		errors.append("MatchInput is already configured.")
	return errors

func snapshot() -> Dictionary:
	return _snapshot.duplicate(true)

static func validate(data: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not _primitive(data): errors.append("MatchInput accepts finite primitive snapshots only.")
	if not data.get("fixture_id") is String or data.get("fixture_id", "").strip_edges().is_empty(): errors.append("Invalid fixture ID.")
	if not data.get("seed") is int: errors.append("Seed must be int64.")
	if data.get("engine_version") != ENGINE_VERSION: errors.append("Unsupported Match Engine version.")
	var config = data.get("config")
	if not config is Dictionary: errors.append("Missing match config.")
	else:
		if config.get("purpose") != "TEST / PLACEHOLDER" or config.get("version") != "phase-4-test-v1": errors.append("Unsupported match config.")
		for key in ["home_initiative", "fatigue_per_minute", "opportunity_rate"]:
			var value = config.get(key)
			if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0.0 or float(value) > (1.0 if key != "home_initiative" else 0.1): errors.append("Invalid match parameter: " + key)
	var ids: Dictionary = {}
	for side in ["home", "away"]:
		var team = data.get(side)
		if not team is Dictionary:
			errors.append("Missing team: " + side)
			continue
		errors.append_array(validate_team(team))
		if team.has("roles"): errors.append("Initial lineup must use natural broad positions.")
		if team.get("players") is Dictionary:
			for id in team.players:
				if ids.has(id): errors.append("Player appears on both teams.")
				ids[id] = true
	if data.get("home") is Dictionary and data.get("away") is Dictionary and data.home.get("club_id") == data.away.get("club_id"): errors.append("Same club on both sides.")
	return errors

static func _primitive(value: Variant) -> bool:
	if value is Dictionary:
		for key in value:
			if not key is String or not _primitive(value[key]): return false
		return true
	if value is Array:
		for item in value:
			if not _primitive(item): return false
		return true
	if value is float: return is_finite(value)
	return value == null or value is String or value is int or value is bool

static func validate_team(team: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not team.get("club_id") is String or team.get("club_id", "").is_empty(): errors.append("Invalid club ID.")
	if team.get("formation") not in FORMATIONS: errors.append("Invalid formation.")
	if team.get("tactic") not in TACTICS: errors.append("Invalid tactic.")
	if not team.get("players") is Dictionary or not team.get("starters") is Array or not team.get("bench") is Array:
		errors.append("Invalid roster snapshot.")
		return errors
	if team.starters.size() != 11 or team.bench.size() > 7: errors.append("Expected eleven starters and up to seven reserves.")
	var seen: Dictionary = {}
	var counts := {"GK": 0, "DEF": 0, "MID": 0, "ATT": 0}
	for id in team.starters + team.bench:
		if not id is String or id.is_empty() or seen.has(id) or not team.players.has(id):
			errors.append("Duplicate/missing player.")
			continue
		seen[id] = true
	for id in team.players:
		var player = team.players[id]
		if not id is String or id.is_empty() or not player is Dictionary:
			errors.append("Invalid player record.")
			continue
		if player.get("position") not in counts: errors.append("Invalid broad position.")
		for key in ["overall", "condition"]:
			var value = player.get(key)
			if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0 or float(value) > 100: errors.append("Invalid player " + key)
	for id in team.starters:
		if team.players.has(id) and team.players[id] is Dictionary:
			var position = team.players[id].get("position")
			if team.has("roles"):
				if not team.roles is Dictionary: errors.append("Invalid field roles.")
				else: position = team.roles.get(id)
			if position not in counts: errors.append("Invalid on-field role.")
			if position == "GK" and team.players[id].get("position") != "GK": errors.append("Keeper role requires a goalkeeper.")
			if team.players[id].get("position") == "GK" and position != "GK": errors.append("Goalkeepers cannot fill outfield roles.")
			if counts.has(position): counts[position] += 1
	if team.get("formation") in FORMATIONS and counts != FORMATIONS[team.formation]: errors.append("Lineup sectors incompatible with formation.")
	return errors
