extends RefCounted
## VERTICAL SLICE PLACEHOLDER: natural position, descending overall, stable ID tie.
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")

func select(world, club_id: String, formation: String) -> Dictionary:
	if formation not in MatchInputModel.FORMATIONS: return {}
	var ids: Array = Array(world.roster_ids(club_id))
	ids.sort_custom(func(a, b):
		if world.players[a].overall != world.players[b].overall: return world.players[a].overall > world.players[b].overall
		return a < b)
	var starters: Array = []
	for position in ["GK", "DEF", "MID", "ATT"]:
		var count: int = 0
		for id in ids:
			if world.players[id].position == position and count < MatchInputModel.FORMATIONS[formation][position]:
				starters.append(id)
				count += 1
	var bench: Array = []
	for id in ids:
		if id not in starters and bench.size() < 7: bench.append(id)
	return {"club_id": club_id, "starters": starters, "bench": bench}
