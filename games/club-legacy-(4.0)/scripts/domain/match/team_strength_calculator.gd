extends RefCounted
## TEST: effective quality = overall * (0.35 + 0.65 * condition/100).
## Sum per broad sector / reference counts (4 DEF,4 MID,2 ATT); GK separately.
## This preserves formation allocation instead of a single average determining play.
func calculate(team: Dictionary) -> Dictionary:
	var sectors := {"GK": 0.0, "DEF": 0.0, "MID": 0.0, "ATT": 0.0}
	for id in team.starters:
		var player: Dictionary = team.players[id]
		var role: String = team.get("roles", {}).get(id, player.position)
		sectors[role] += effective(player) * (1.0 if role == player.position else 0.65)
	return {"keeper": sectors.GK, "defense": sectors.DEF / 4.0, "midfield": sectors.MID / 4.0, "attack": sectors.ATT / 2.0}

func effective(player: Dictionary) -> float:
	return float(player.overall) * (0.35 + 0.65 * float(player.condition) / 100.0)
