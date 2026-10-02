extends RefCounted
## TEST sector trade-offs, not a direct goal probability modifier.
static func compose(strength: Dictionary, tactic: String) -> Dictionary:
	var attack_support: float = 1.0
	var cover: float = 1.0
	var effort: float = 1.0
	var exposure: float = 1.0
	if tactic == "OFENSIVA":
		attack_support = 1.20
		cover = 0.82
		effort = 1.35
		exposure = 1.20
	elif tactic == "CAUTELOSA":
		attack_support = 0.78
		cover = 1.16
		effort = 0.90
		exposure = 0.82
	return {"creation": strength.midfield * attack_support, "attack": strength.attack * attack_support, "cover": strength.defense * cover, "keeper": strength.keeper, "exposure": exposure, "effort": effort}
