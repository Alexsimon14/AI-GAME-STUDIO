extends RefCounted
const CompetitionCodec = preload("res://scripts/persistence/competition_codec.gd")
## Explicit Phase 2 schema. Integer fields are decimal strings, never JSON floats.
const World = preload("res://scripts/domain/models/world_state.gd")
const WorldConfig = preload("res://resources/config/world_config.gd")
const CAREER = preload("res://scripts/domain/models/career.gd")
const MANAGER = preload("res://scripts/domain/models/manager.gd")
const CLUB = preload("res://scripts/domain/models/club.gd")
const PLAYER = preload("res://scripts/domain/models/player.gd")
const CONTRACT = preload("res://scripts/domain/models/contract.gd")
const LEAGUE = preload("res://scripts/domain/models/league.gd")
const SCHEMAS: Dictionary = {"career":{"id":"s","seed":"i","manager_id":"s","next_entity_serial":"i"},"manager":{"id":"s","name":"s","reputation":"i","employment_contract_id":"s","history":"a"},"club":{"id":"s","name":"s","league_id":"s","profile":"s","reputation":"i","fans":"i","stadium_name":"s","capacity":"i","cash":"i","training_level":"i","expectation":"s"},"player":{"id":"s","name":"s","age":"i","position":"s","overall":"i","potential":"i","condition":"i","contract_id":"s"},"contract":{"id":"s","kind":"s","subject_id":"s","club_id":"s","active":"b","end_season":"i","salary":"i"},"league":{"id":"s","name":"s","tier":"i"}}

func encode(world) -> Dictionary:
	var errors: PackedStringArray = world.validation_errors()
	if not errors.is_empty():
		return {"payload": null, "errors": errors}
	var payload := {"selected_profile": world.selected_profile,
		"career": _encode_entity(world.career, "career"), "manager": _encode_entity(world.manager, "manager")}
	payload.career["config_snapshot"] = _config_to_json(world.career.config_snapshot)
	for pair in [["clubs", "club"], ["players", "player"], ["contracts", "contract"], ["leagues", "league"]]:
		payload[pair[0]] = []
		var ids: Array = world.get(pair[0]).keys()
		ids.sort()
		for id in ids:
			payload[pair[0]].append(_encode_entity(world.get(pair[0])[id], pair[1]))
	payload.merge(CompetitionCodec.new().encode(world))
	return {"payload": payload, "errors": errors}

func _encode_entity(entity, kind: String) -> Dictionary:
	var output: Dictionary = {}
	for field in SCHEMAS[kind]:
		var value = entity.get(field)
		output[field] = str(value) if SCHEMAS[kind][field] == "i" else value
	return output

func decode(payload: Variant, legacy_schema_one: bool = false) -> Dictionary:
	var errors := PackedStringArray()
	if not payload is Dictionary:
		return _failure("Payload must be a dictionary.")
	for key in ["selected_profile", "career", "manager", "clubs", "players", "contracts", "leagues"]:
		if not payload.has(key):
			return _failure("Missing payload field: " + key)
	if not payload.selected_profile is String:
		return _failure("Invalid selected_profile type.")
	var world = World.new()
	world.selected_profile = payload.selected_profile
	world.career = _decode_entity(payload.career, "career", CAREER, errors)
	world.manager = _decode_entity(payload.manager, "manager", MANAGER, errors)
	if not errors.is_empty():
		return {"world": null, "errors": errors}
	if not payload.career.has("config_snapshot"):
		return _failure("Missing effective configuration.")
	var config_result: Dictionary = _config_from_json(payload.career.config_snapshot)
	if not config_result.errors.is_empty():
		return {"world": null, "errors": config_result.errors}
	world.career.config_snapshot = config_result.snapshot
	for pair in [["clubs", "club", CLUB], ["players", "player", PLAYER], ["contracts", "contract", CONTRACT], ["leagues", "league", LEAGUE]]:
		if not payload[pair[0]] is Array or payload[pair[0]].size() > 1000:
			return _failure("Invalid entity collection: " + pair[0])
		for record in payload[pair[0]]:
			var entity = _decode_entity(record, pair[1], pair[2], errors)
			if entity == null:
				return {"world": null, "errors": errors}
			var collection: Dictionary = world.get(pair[0])
			if collection.has(entity.id):
				return _failure("Duplicate entity ID: " + entity.id)
			collection[entity.id] = entity
	if not legacy_schema_one:
		errors = CompetitionCodec.new().decode(payload, world)
		if not errors.is_empty(): return {"world": null, "errors": errors}
	errors = world.validation_errors()
	if world.career.next_entity_serial < 1:
		errors.append("Invalid ID counter.")
	# Counter must remain above all allocated serials; namespace is retained, not rebuilt.
	for collection in [world.clubs, world.players, world.contracts, world.leagues]:
		for entity in collection.values():
			_validate_id(entity.id, world.career, errors)
	_validate_id(world.manager.id, world.career, errors)
	if world.career.id.is_empty() or not world.career.id.begins_with("career:"):
		errors.append("Invalid career namespace.")
	if world.selected_profile not in ["PEQUENO", "MEDIO", "ELITE"]:
		errors.append("Invalid profile.")
	if not world.manager.history.is_empty():
		errors.append("Phase 2 initial career history must be empty.")
	if world.manager.reputation < 0 or world.manager.reputation > 100:
		errors.append("Invalid reputation.")
	var tiers: Array = []
	for league in world.leagues.values():
		tiers.append(league.tier)
	tiers.sort()
	if tiers != [1, 2]:
		errors.append("Invalid division tiers.")
	for club in world.clubs.values():
		if club.profile not in ["PEQUENO", "MEDIO", "ELITE"] or club.cash < 0 or club.fans < 0 or club.capacity < 0 or club.training_level < 0:
			errors.append("Invalid initial club attributes.")
	return {"world": world if errors.is_empty() else null, "errors": errors}

func _validate_id(id: String, career, errors: PackedStringArray) -> void:
	if not id.begins_with(career.id + ":"):
		errors.append("Entity outside career namespace.")
	var serial: String = id.get_slice(":", id.get_slice_count(":") - 1)
	if not valid_integer(serial) or int(serial) < 1 or int(serial) >= career.next_entity_serial:
		errors.append("ID counter/serial inconsistent.")

func _decode_entity(record: Variant, kind: String, model, errors: PackedStringArray):
	if not record is Dictionary:
		errors.append("Invalid entity record.")
		return null
	var entity = model.new()
	for field in SCHEMAS[kind]:
		if not record.has(field):
			errors.append("Missing entity field: " + kind + "/" + field)
			return null
		var value = record[field]
		match SCHEMAS[kind][field]:
			"s":
				if not value is String:
					errors.append("Expected string: " + field)
					return null
			"i":
				if not valid_integer(value):
					errors.append("Expected canonical integer string: " + field)
					return null
				value = int(value)
			"b":
				if not value is bool:
					errors.append("Expected boolean: " + field)
					return null
			"a":
				if not value is Array or not value.is_empty():
					errors.append("Initial history must be empty array.")
					return null
		entity.set(field, value)
	return entity

func valid_integer(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(int(value)) == value

func _failure(reason: String) -> Dictionary:
	return {"world": null, "errors": PackedStringArray([reason])}

func _config_to_json(snapshot: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in snapshot:
		var value = snapshot[key]
		if value is Vector2i:
			result[key] = [str(value.x), str(value.y)]
		elif value is PackedStringArray:
			result[key] = Array(value)
		elif value is int:
			result[key] = str(value)
		elif value is Dictionary:
			result[key] = _config_to_json(value)
		else:
			result[key] = value
	return result

func _config_from_json(data: Variant) -> Dictionary:
	var error := {"snapshot": {}, "errors": PackedStringArray(["Invalid effective configuration."])}
	if not data is Dictionary:
		return error
	var config = WorldConfig.new()
	for pair in [["version", "config_version"], ["purpose", "purpose"]]:
		if not data.get(pair[0]) is String:
			return error
		config.set(pair[1], data[pair[0]])
	for pair in [["manager_reputation", "manager_reputation"], ["condition", "initial_condition"]]:
		if not valid_integer(data.get(pair[0])):
			return error
		config.set(pair[1], int(data[pair[0]]))
	for pair in [["age_range", "age_range"], ["duration", "contract_duration_range"]]:
		var bounds = _range_from_json(data.get(pair[0]))
		if bounds == null:
			return error
		config.set(pair[1], bounds)
	for key in ["first_names", "last_names", "club_names", "league_names", "club_profiles"]:
		if not data.get(key) is Array:
			return error
		for value in data[key]:
			if not value is String:
				return error
		config.set(key, PackedStringArray(data[key]))
	if not data.get("positions") is Dictionary or not data.get("profiles") is Dictionary:
		return error
	config.positions = {}
	for key in data.positions:
		if not valid_integer(data.positions[key]):
			return error
		config.positions[key] = int(data.positions[key])
	config.profiles = {}
	for profile in data.profiles:
		if not data.profiles[profile] is Dictionary:
			return error
		config.profiles[profile] = {}
		var source: Dictionary = data.profiles[profile]
		for key in ["overall", "potential", "salary"]:
			var bounds = _range_from_json(source.get(key))
			if bounds == null:
				return error
			config.profiles[profile][key] = bounds
		for key in ["cash", "fans", "capacity", "reputation", "training"]:
			if not valid_integer(source.get(key)):
				return error
			config.profiles[profile][key] = int(source[key])
		if not source.get("expectation") is String:
			return error
		config.profiles[profile].expectation = source.expectation
	var errors: PackedStringArray = config.validation_errors()
	return {"snapshot": config.snapshot() if errors.is_empty() else {}, "errors": errors}

func _range_from_json(value: Variant) -> Variant:
	if not value is Array or value.size() != 2 or not valid_integer(value[0]) or not valid_integer(value[1]):
		return null
	for item in value:
		if int(item) < -2147483648 or int(item) > 2147483647:
			return null
	return Vector2i(int(value[0]), int(value[1]))
