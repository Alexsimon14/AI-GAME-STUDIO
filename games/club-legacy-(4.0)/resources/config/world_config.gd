extends Resource
## All numeric generation data is TEST / PLACEHOLDER, not final balance.

@export var config_version: String = "phase-1-test-v1"
@export var purpose: String = "TEST / PLACEHOLDER"
@export var manager_reputation: int = 70
@export var age_range: Vector2i = Vector2i(18, 33)
@export var initial_condition: int = 100
@export var contract_duration_range: Vector2i = Vector2i(1, 2)
@export var positions: Dictionary = {"GK": 2, "DEF": 6, "MID": 6, "ATT": 4}
@export var first_names: PackedStringArray = ["Arven", "Belio", "Cevan", "Darel", "Evin", "Faron", "Galen", "Havel"]
@export var last_names: PackedStringArray = ["Velora", "Neraval", "Ostrel", "Selvar", "Talven", "Uldar", "Virel", "Zerand"]
@export var club_names: PackedStringArray = ["Aurora de Neral", "Vale de Tervan", "Porto de Luren", "Estrela de Soval", "Monte de Ardel", "União de Veldra", "Riacho de Belven", "Lago de Orven", "Pedra de Ceral", "Campos de Darel", "Vila de Erel", "Horizonte de Farel"]
@export var league_names: PackedStringArray = ["Liga de Neral I", "Liga de Neral II"]
@export var profiles: Dictionary = {
	"PEQUENO": {"overall": Vector2i(30, 44), "potential": Vector2i(45, 60), "salary": Vector2i(10, 20), "cash": 20000, "fans": 1000, "capacity": 1500, "reputation": 20, "training": 0, "expectation": "Campanha modesta — TEST"},
	"MEDIO": {"overall": Vector2i(50, 64), "potential": Vector2i(65, 80), "salary": Vector2i(30, 40), "cash": 60000, "fans": 4000, "capacity": 5000, "reputation": 45, "training": 1, "expectation": "Campanha intermediária — TEST"},
	"ELITE": {"overall": Vector2i(70, 84), "potential": Vector2i(85, 99), "salary": Vector2i(50, 60), "cash": 120000, "fans": 10000, "capacity": 12000, "reputation": 70, "training": 2, "expectation": "Disputar título — TEST"}
}
@export var club_profiles: PackedStringArray = ["ELITE", "ELITE", "ELITE", "MEDIO", "MEDIO", "MEDIO", "MEDIO", "MEDIO", "PEQUENO", "PEQUENO", "PEQUENO", "PEQUENO"]

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if purpose != "TEST / PLACEHOLDER" or config_version.is_empty():
		errors.append("Generation configuration must be versioned TEST / PLACEHOLDER.")
	if club_names.size() != 12 or club_profiles.size() != 12 or league_names.size() != 2:
		errors.append("Catalog must define 12 clubs and 2 leagues.")
	if first_names.is_empty() or last_names.is_empty():
		errors.append("Fictional name catalog is empty.")
	for catalog in [first_names, last_names, club_names, league_names]:
		for value in catalog:
			if value.strip_edges().is_empty():
				errors.append("Catalog contains an empty name.")
	if positions != {"GK": 2, "DEF": 6, "MID": 6, "ATT": 4}:
		errors.append("Phase 1 requires approved TEST position coverage 2/6/6/4.")
	if age_range.x < 1 or age_range.x > age_range.y or initial_condition < 1 or initial_condition > 100:
		errors.append("Invalid age or condition range.")
	if contract_duration_range.x < 1 or contract_duration_range.y > 2 or contract_duration_range.x > contract_duration_range.y:
		errors.append("Invalid initial contract duration.")
	if manager_reputation < 0 or manager_reputation > 100:
		errors.append("Invalid TEST manager reputation.")
	for profile in ["PEQUENO", "MEDIO", "ELITE"]:
		if not profiles.has(profile) or not profiles[profile] is Dictionary:
			errors.append("Missing profile: " + profile)
			continue
		var data: Dictionary = profiles[profile]
		for key in ["overall", "potential", "salary"]:
			if not data.get(key) is Vector2i:
				errors.append("Invalid range: " + profile + "/" + key)
				continue
			var bounds: Vector2i = data[key]
			if bounds.x < 0 or bounds.x > bounds.y or (key != "salary" and bounds.y > 100):
				errors.append("Invalid range bounds: " + profile + "/" + key)
		if data.get("overall") is Vector2i and data.get("potential") is Vector2i:
			if data.potential.x < data.overall.y:
				errors.append("Potential range must cover overall.")
		for key in ["cash", "fans", "capacity", "reputation", "training"]:
			if not data.get(key) is int or data.get(key, -1) < 0:
				errors.append("Invalid profile field: " + key)
		if not data.get("expectation") is String or str(data.get("expectation", "")).is_empty():
			errors.append("Missing expectation.")
	for profile in club_profiles:
		if profile not in ["PEQUENO", "MEDIO", "ELITE"]:
			errors.append("Unknown catalog profile.")
	for profile in ["PEQUENO", "MEDIO", "ELITE"]:
		if profile not in club_profiles:
			errors.append("Profile not selectable: " + profile)
	return errors

func snapshot() -> Dictionary:
	return {"version": config_version, "purpose": purpose, "manager_reputation": manager_reputation,
		"age_range": age_range, "condition": initial_condition, "duration": contract_duration_range,
		"positions": positions.duplicate(true), "first_names": first_names.duplicate(),
		"last_names": last_names.duplicate(), "club_names": club_names.duplicate(),
		"league_names": league_names.duplicate(), "profiles": profiles.duplicate(true),
		"club_profiles": club_profiles.duplicate()}
