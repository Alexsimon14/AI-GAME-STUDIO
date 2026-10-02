extends RefCounted
## Pure projection: fixtures are the only source of points/statistics.

func calculate(world, league_id: String) -> Array:
	if world.season == null or not world.season.members.has(league_id):
		return []
	var rows: Dictionary = {}
	for club_id in world.season.members[league_id]:
		rows[club_id] = {"club_id": club_id, "played": 0, "wins": 0, "draws": 0,
			"losses": 0, "goals_for": 0, "goals_against": 0, "goal_difference": 0, "points": 0}
	for fixture in world.fixtures.values():
		if fixture.league_id != league_id or fixture.status != "COMPLETED":
			continue
		_apply(rows[fixture.home_club_id], fixture.home_goals, fixture.away_goals)
		_apply(rows[fixture.away_club_id], fixture.away_goals, fixture.home_goals)
	var ordered: Array = rows.values()
	var tie_order: Array = world.season.tiebreak_order[league_id]
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return precedes(a, b, tie_order))
	return ordered

func precedes(a: Dictionary, b: Dictionary, tie_order: Array) -> bool:
	for metric in ["points", "goal_difference", "goals_for", "wins"]:
		if a[metric] != b[metric]: return a[metric] > b[metric]
	return tie_order.find(a.club_id) < tie_order.find(b.club_id)

func _apply(row: Dictionary, scored: int, conceded: int) -> void:
	row.played += 1
	row.goals_for += scored
	row.goals_against += conceded
	row.goal_difference = row.goals_for - row.goals_against
	if scored > conceded:
		row.wins += 1
		row.points += 3
	elif scored == conceded:
		row.draws += 1
		row.points += 1
	else:
		row.losses += 1
