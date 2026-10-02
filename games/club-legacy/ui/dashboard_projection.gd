extends RefCounted
## Read-only projection. Standings authority stays in TableCalculator.
static func build(flow) -> Dictionary:
	if flow.world == null: return {}
	var world = flow.world
	var id: String = flow.club_id()
	var club = world.clubs[id]
	var rows: Array = flow.standings(club.league_id)
	var own: Dictionary = {}
	var position: int = 0
	for i in range(rows.size()):
		if rows[i].club_id == id: own = rows[i]; position = i + 1
	var recent: Array = []
	var upcoming: Array = []
	for f in world.fixtures.values():
		if id not in [f.home_club_id, f.away_club_id]: continue
		if f.status == "COMPLETED": recent.append(f)
		else: upcoming.append(f)
	recent.sort_custom(func(a, b): return a.round > b.round)
	upcoming.sort_custom(func(a, b): return a.round < b.round)
	var roster: Array = Array(world.roster_ids(id))
	var average: float = 0
	var best: int = 0
	for player_id in roster:
		var p = world.players[player_id]
		average += p.condition
		best = maxi(best, p.overall)
	roster.sort_custom(func(a, b): return world.players[a].overall > world.players[b].overall if world.players[a].overall != world.players[b].overall else a < b)
	return {"standings": rows, "performance": own, "position": position, "recent": recent.slice(0, 3), "upcoming": upcoming.slice(0, 4), "roster_count": roster.size(), "condition": average / max(1, roster.size()), "best_overall": best, "highlights": roster.slice(0, 2)}

