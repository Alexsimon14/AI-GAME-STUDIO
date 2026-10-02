extends RefCounted
## Thin boundary only: detached world -> input; confirmed result -> SeasonService.
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")
const Season = preload("res://scripts/domain/services/season_service.gd")
const ResultModel = preload("res://scripts/domain/match/match_result.gd")
const Selector = preload("res://scripts/domain/services/lineup_selector.gd")

func build(world, fixture_id: String, seed_value: Variant, formation: String = "4-4-2", tactic: String = "EQUILIBRADA", selection: Dictionary = {}) -> Dictionary:
	if not world.fixtures.has(fixture_id) or formation not in MatchInputModel.FORMATIONS: return {"input": null, "errors": PackedStringArray(["Invalid fixture/formation."])}
	var fixture = world.fixtures[fixture_id]
	var data := {"fixture_id": fixture.id, "seed": seed_value, "engine_version": MatchInputModel.ENGINE_VERSION, "config": MatchInputModel.defaults()}
	for side in ["home", "away"]:
		var club_id: String = fixture.home_club_id if side == "home" else fixture.away_club_id
		var players: Dictionary = {}
		var available: Array = []
		for id in world.roster_ids(club_id):
			var p = world.players[id]
			players[id] = {"position": p.position, "overall": p.overall, "condition": p.condition}
			available.append(id)
		var chosen: Dictionary = Selector.new().select(world, club_id, formation)
		if selection.get("club_id") == club_id:
			if not selection.get("starters") is Array or not selection.get("bench") is Array: return {"input": null, "errors": PackedStringArray(["Invalid lineup selection."])}
			chosen = selection
			for id in chosen.starters + chosen.bench:
				if id not in available: return {"input": null, "errors": PackedStringArray(["Player outside club roster."])}
		var starters: Array = chosen.starters.duplicate()
		var bench: Array = chosen.bench.duplicate()
		data[side] = {"club_id": club_id, "players": players, "starters": starters, "bench": bench, "formation": formation, "tactic": tactic}
		if not selection.is_empty() and selection.get("club_id") != fixture.home_club_id and selection.get("club_id") != fixture.away_club_id: return {"input": null, "errors": PackedStringArray(["Selection club outside fixture."])}
	var input = MatchInputModel.new()
	var errors: PackedStringArray = input.configure(data)
	return {"input": input if errors.is_empty() else null, "errors": errors}

func submit(world, result, operation_key: String) -> Dictionary:
	if result == null or not result is RefCounted or result.get_script() != ResultModel: return {"errors": PackedStringArray(["Missing/invalid MatchResult."])}
	var data: Dictionary = result.snapshot()
	if data.get("phase") != "FINISHED" or data.get("minute") != 90 or not data.get("fixture_id") is String or not data.get("home_club_id") is String or not data.get("away_club_id") is String or not data.get("stats") is Dictionary: return {"errors": PackedStringArray(["Invalid final result fields."])}
	for side in ["home", "away"]:
		if not data.stats.get(side) is Dictionary or not data.stats[side].get("goals") is int or data.stats[side].goals < 0: return {"errors": PackedStringArray(["Invalid result goals."])}
	if not world.fixtures.has(data.fixture_id): return {"errors": PackedStringArray(["Missing result fixture."])}
	var fixture = world.fixtures[data.fixture_id]
	if data.home_club_id != fixture.home_club_id or data.away_club_id != fixture.away_club_id: return {"errors": PackedStringArray(["Result participants mismatch."])}
	return Season.new().submit_result(world, fixture.id, data.stats.home.goals, data.stats.away.goals, operation_key)
