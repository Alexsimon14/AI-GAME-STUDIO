extends RefCounted
## Initiative controls possession ticks; an opportunity must then beat coverage.
func generate(attacking: Dictionary, defending: Dictionary, rng: RandomNumberGenerator, rate: float) -> Dictionary:
	var construction: float = (attacking.creation + attacking.attack * 0.35 + 10.0) / (attacking.creation + attacking.attack * 0.35 + defending.cover + 20.0)
	if rng.randf() >= rate * construction * defending.exposure: return {}
	var quality: float = clampf(0.15 + 0.50 * (attacking.attack + 10.0) / (attacking.attack + defending.cover + 20.0) + rng.randf_range(-0.15, 0.15), 0.05, 0.85)
	return {"quality": quality, "category": "CLEAR" if quality >= 0.48 else "ORDINARY", "opponent_exposure": defending.exposure, "creation": attacking.creation, "cover": defending.cover}
