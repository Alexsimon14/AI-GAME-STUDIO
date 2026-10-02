extends RefCounted
const Strength = preload("res://scripts/domain/match/team_strength_calculator.gd")

func resolve(chance: Dictionary, attacking: Dictionary, defending: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var eligible: Array = []
	var total: float = 0.0
	var strength = Strength.new()
	for id in attacking.starters:
		var p: Dictionary = attacking.players[id]
		if p.position == "GK": continue
		var role: String = attacking.get("roles", {}).get(id, p.position)
		var adequacy: float = 1.0 if role == p.position else 0.65
		var weight: float = (strength.effective(p) * adequacy + 1.0) * (3.0 if role == "ATT" else (1.5 if role == "MID" else 0.4))
		eligible.append([id, weight])
		total += weight
	var draw: float = rng.randf() * total
	var shooter: String = eligible.back()[0]
	for pair in eligible:
		draw -= pair[1]
		if draw <= 0:
			shooter = pair[0]
			break
	if rng.randf() > 0.88: return {"kind": "CHANCE_LOST", "player_id": shooter}
	if rng.randf() > 0.24 + chance.quality * 0.65: return {"kind": "SHOT_OFF_TARGET", "player_id": shooter}
	var player: Dictionary = attacking.players[shooter]
	var finishing: float = strength.effective(player) * (1.0 if attacking.get("roles", {}).get(shooter, player.position) == player.position else 0.65)
	var keeper: float = defending.keeper
	var conversion: float = chance.quality * (0.45 + (finishing + 10.0) / (finishing + keeper + 20.0))
	return {"kind": "GOAL" if rng.randf() < conversion else "SAVE", "player_id": shooter}
