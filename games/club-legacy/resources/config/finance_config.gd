extends Resource
## Integer fictional units. All parameters are experimental, not final balance.
const LIMIT: int = 1000000000000
@export var config_id: String = "phase-6-test-v1"
@export var purpose: String = "TEST / PLACEHOLDER"
@export var ticket_price: int = 2
@export var occupancy_basis_points: Dictionary = {"PEQUENO": 6000, "MEDIO": 7000, "ELITE": 8000}
@export var maintenance_per_round: Dictionary = {"PEQUENO": 100, "MEDIO": 300, "ELITE": 700}

func snapshot() -> Dictionary:
	return {"config_id": config_id, "purpose": purpose, "ticket_price": ticket_price,
		"occupancy_basis_points": occupancy_basis_points.duplicate(true),
		"maintenance_per_round": maintenance_per_round.duplicate(true)}

func validation_errors() -> PackedStringArray:
	return validate_snapshot(snapshot())

static func validate_snapshot(data: Variant) -> PackedStringArray:
	var errors := PackedStringArray()
	if not data is Dictionary:
		return PackedStringArray(["Invalid finance configuration."])
	if data.keys().size() != 5 or not data.get("config_id") is String or data.get("config_id", "").is_empty() or data.get("purpose") != "TEST / PLACEHOLDER":
		errors.append("Invalid finance configuration identity/purpose.")
	var price: Variant = data.get("ticket_price")
	if typeof(price) != TYPE_INT or price < 0 or price > 1000000:
		errors.append("Invalid integer ticket price.")
	for field in ["occupancy_basis_points", "maintenance_per_round"]:
		var values: Variant = data.get(field)
		if not values is Dictionary or values.size() != 3:
			errors.append("Invalid finance profile map: " + field)
			continue
		for profile in ["PEQUENO", "MEDIO", "ELITE"]:
			var value: Variant = values.get(profile)
			var maximum: int = 10000 if field == "occupancy_basis_points" else LIMIT
			if typeof(value) != TYPE_INT or value < 0 or value > maximum:
				errors.append("Invalid finance parameter: " + field + "/" + profile)
	return errors
