extends RefCounted

const Factory = preload("res://scripts/domain/services/world_factory.gd")
const Config = preload("res://resources/config/world_config.gd")
const DefaultConfig = preload("res://resources/config/world_config.tres")
const Contract = preload("res://scripts/domain/models/contract.gd")

func run(check: Callable) -> void:
	var factory = Factory.new()
	var config_before: Dictionary = DefaultConfig.snapshot()
	var outcome: Dictionary = factory.create(DefaultConfig, 12345, "Treinador Teste", "PEQUENO", "test-world")
	check.call(outcome.errors.is_empty() and outcome.world != null, "WorldFactory creates valid initial world")
	if outcome.world == null:
		return
	var world = outcome.world
	check.call(world is RefCounted and not world is Node, "WorldState has no Node dependency")
	check.call(world.clubs.size() == 12, "12 clubs")
	check.call(world.leagues.size() == 2, "2 divisions")
	check.call(world.players.size() == 216, "216 athletes")
	check.call(world.contracts.size() == 217, "216 athlete contracts and one employment")
	check.call(world.manager.name == "Treinador Teste" and world.manager.history.is_empty(), "Manager created with empty history")
	check.call(world.career.manager_id == world.manager.id, "Manager belongs to career by ID")
	for league_id in world.leagues:
		var count: int = 0
		for club in world.clubs.values():
			if club.league_id == league_id:
				count += 1
		check.call(count == 6, "Six clubs per division: " + league_id)
	var unique_players: Dictionary = {}
	for club_id in world.clubs:
		var roster: PackedStringArray = world.roster_ids(club_id)
		check.call(roster.size() == 18, "18 athletes: " + club_id)
		var coverage := {"GK": 0, "DEF": 0, "MID": 0, "ATT": 0}
		for player_id in roster:
			unique_players[player_id] = true
			coverage[world.players[player_id].position] += 1
		check.call(coverage == {"GK": 2, "DEF": 6, "MID": 6, "ATT": 4}, "All three formations covered: " + club_id)
	check.call(unique_players.size() == 216, "No athlete belongs to two clubs")
	var ids: Dictionary = {}
	var total: int = 2
	ids[world.career.id] = true
	ids[world.manager.id] = true
	for collection in [world.clubs, world.players, world.contracts, world.leagues]:
		total += collection.size()
		for entity in collection.values():
			ids[entity.id] = true
	check.call(ids.size() == total, "All entity IDs globally unique")
	check.call(world.validation_errors().is_empty(), "Contracts and references consistent")
	for profile in ["PEQUENO", "MEDIO", "ELITE"]:
		var candidate = factory.create(DefaultConfig, 12345, "Treinador Teste", profile, "test-world").world
		check.call(candidate != null and candidate.validation_errors().is_empty(), "Profile creates valid world: " + profile)
		if candidate != null:
			var job = candidate.contracts[candidate.manager.employment_contract_id]
			check.call(candidate.clubs[job.club_id].profile == profile, "First employment matches: " + profile)
	var second = factory.create(DefaultConfig, 12345, "Treinador Teste", "PEQUENO", "test-world").world
	check.call(structure(world) == structure(second), "Same seed/config/namespace/input yields structurally identical world")
	var varied = factory.create(DefaultConfig, 54321, "Treinador Teste", "PEQUENO", "test-world").world
	check.call(structure(world) != structure(varied), "Different seed varies generated athletes")
	check.call(DefaultConfig.snapshot() == config_before, "Factory leaves configuration unchanged")
	world.career.config_snapshot.profiles.PEQUENO.cash = -1
	check.call(DefaultConfig.snapshot() == config_before, "Career configuration snapshot does not alias Resource")
	var original_player = world.players.values()[0]
	var original_club = world.clubs.values()[0]
	original_player.name = "Renomeado"
	original_club.name = "Clube renomeado"
	world.manager.name = "Nome alterado"
	check.call(world.validation_errors().is_empty(), "Renaming preserves ID relationships")
	original_player.condition = 50
	check.call(DefaultConfig.initial_condition == 100 and second.players[original_player.id].condition == 100, "World state isolated from config and other careers")
	var cash_before: Dictionary = {}
	var rosters_before: Dictionary = {}
	for club in world.clubs.values():
		cash_before[club.id] = club.cash
		rosters_before[club.id] = world.roster_ids(club.id)
	var job = world.contracts[world.manager.employment_contract_id]
	var original_job_club: String = job.club_id
	job.club_id = world.clubs.keys()[0]
	for club in world.clubs.values():
		check.call(club.cash == cash_before[club.id] and world.roster_ids(club.id) == rosters_before[club.id], "Employment reference does not move cash/roster: " + club.id)
	job.club_id = original_job_club
	var broken = factory.create(DefaultConfig, 12345, "Treinador", "PEQUENO", "broken").world
	var athlete = broken.players.values()[0]
	var duplicate = Contract.new()
	duplicate.id = broken.career.allocate_id("contract")
	duplicate.kind = "athlete"
	duplicate.subject_id = athlete.id
	duplicate.club_id = broken.clubs.keys()[1]
	broken.contracts[duplicate.id] = duplicate
	check.call(not broken.validation_errors().is_empty(), "Duplicate active athlete contract rejected")
	broken.contracts.erase(duplicate.id)
	var athlete_contract = broken.contracts[athlete.contract_id]
	athlete_contract.club_id = "missing"
	check.call(not broken.validation_errors().is_empty(), "Dangling club reference rejected")
	athlete_contract.club_id = broken.clubs.keys()[0]
	athlete_contract.subject_id = "missing"
	check.call(not broken.validation_errors().is_empty(), "Dangling subject reference rejected")
	athlete_contract.subject_id = athlete.id
	var previous_id: String = athlete.id
	athlete.id = broken.manager.id
	check.call(not broken.validation_errors().is_empty(), "Duplicate entity ID rejected")
	athlete.id = previous_id
	var previous_position: String = athlete.position
	for player in broken.players.values():
		if player.position == "GK":
			player.position = "DEF"
	check.call(not broken.validation_errors().is_empty(), "Missing goalkeeper coverage rejected")
	athlete.position = previous_position
	var malformed = Config.new()
	malformed.profiles = malformed.profiles.duplicate(true)
	malformed.profiles.ELITE.erase("salary")
	check.call(factory.create(malformed, 1, "Treinador", "ELITE", "invalid").world == null, "Missing profile generation range rejected")
	var next_id: String = world.career.allocate_id("player")
	check.call(not ids.has(next_id), "Entity counter allocates unused ID after renaming")
	var bad = Config.new()
	bad.age_range = Vector2i(40, 10)
	check.call(factory.create(bad, 1, "Treinador", "PEQUENO", "invalid").world == null, "Invalid generation config rejected")
	check.call(factory.create(null, 1, "Treinador", "PEQUENO", "invalid").world == null, "Missing generation config rejected")
	check.call(factory.create(Resource.new(), 1, "Treinador", "PEQUENO", "invalid").world == null, "Wrong generation config type rejected")
	check.call(factory.create(DefaultConfig, 1, "Treinador", "UNKNOWN", "invalid").world == null, "Unknown profile rejected")
	check.call(factory.create(DefaultConfig, 1, "", "PEQUENO", "invalid").world == null, "Empty manager identity rejected")
	var means := {"PEQUENO": 0.0, "MEDIO": 0.0, "ELITE": 0.0}
	var counts := {"PEQUENO": 0, "MEDIO": 0, "ELITE": 0}
	for club in second.clubs.values():
		for player_id in second.roster_ids(club.id):
			means[club.profile] += second.players[player_id].overall
			counts[club.profile] += 1
	check.call(means.PEQUENO / counts.PEQUENO < means.MEDIO / counts.MEDIO and means.MEDIO / counts.MEDIO < means.ELITE / counts.ELITE, "TEST roster quality increases by profile")

## Test-only structural projection; not save serialization (Phase 2 is excluded).
func structure(world) -> Dictionary:
	var result := {"career": fields(world.career), "manager": fields(world.manager), "profile": world.selected_profile}
	for label in ["clubs", "players", "contracts", "leagues"]:
		result[label] = {}
		for id in world.get(label):
			result[label][id] = fields(world.get(label)[id])
	return result

func fields(entity) -> Dictionary:
	var result: Dictionary = {}
	for property in entity.get_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			result[property.name] = entity.get(property.name)
	return result
