extends RefCounted

const WorldModel = preload("res://scripts/domain/models/world_state.gd")
const CareerModel = preload("res://scripts/domain/models/career.gd")
const ManagerModel = preload("res://scripts/domain/models/manager.gd")
const ClubModel = preload("res://scripts/domain/models/club.gd")
const PlayerModel = preload("res://scripts/domain/models/player.gd")
const ContractModel = preload("res://scripts/domain/models/contract.gd")
const LeagueModel = preload("res://scripts/domain/models/league.gd")
const ConfigModel = preload("res://resources/config/world_config.gd")

func create(config: Resource, seed_value: int, manager_name: String, profile: String, career_id: String) -> Dictionary:
	var errors := PackedStringArray()
	if config == null or config.get_script() != ConfigModel:
		errors.append("World configuration resource is missing/incorrect.")
	else:
		errors = config.call("validation_errors")
	if manager_name.strip_edges().is_empty() or career_id.strip_edges().is_empty():
		errors.append("Manager name and career namespace are required.")
	if profile not in ["PEQUENO", "MEDIO", "ELITE"]:
		errors.append("Unknown initial profile.")
	if not errors.is_empty():
		return {"world": null, "errors": errors}
	var world = WorldModel.new()
	world.selected_profile = profile
	world.career = CareerModel.new()
	world.career.id = "career:" + career_id
	world.career.seed = seed_value
	world.career.config_snapshot = config.call("snapshot")
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	world.manager = ManagerModel.new()
	world.manager.id = world.career.allocate_id("manager")
	world.manager.name = manager_name
	world.manager.reputation = config.manager_reputation
	world.career.manager_id = world.manager.id
	var league_ids: Array[String] = []
	for tier in range(2):
		var league = LeagueModel.new()
		league.id = world.career.allocate_id("league")
		league.name = config.league_names[tier]
		league.tier = tier + 1
		world.leagues[league.id] = league
		league_ids.append(league.id)
	var initial_club_id: String = ""
	for catalog_index in range(12):
		var club = ClubModel.new()
		club.id = world.career.allocate_id("club")
		club.name = config.club_names[catalog_index]
		club.profile = config.club_profiles[catalog_index]
		club.league_id = league_ids[0 if catalog_index < 6 else 1]
		var data: Dictionary = config.profiles[club.profile]
		club.cash = data.cash
		club.fans = data.fans
		club.capacity = data.capacity
		club.reputation = data.reputation
		club.training_level = data.training
		club.stadium_name = "Estádio " + club.name
		club.expectation = data.expectation
		world.clubs[club.id] = club
		if initial_club_id.is_empty() and club.profile == profile:
			initial_club_id = club.id
		for position in ["GK", "DEF", "MID", "ATT"]:
			for _slot in range(config.positions[position]):
				var player = PlayerModel.new()
				player.id = world.career.allocate_id("player")
				player.name = "%s %s" % [config.first_names[rng.randi_range(0, config.first_names.size() - 1)], config.last_names[rng.randi_range(0, config.last_names.size() - 1)]]
				player.age = rng.randi_range(config.age_range.x, config.age_range.y)
				player.position = position
				player.overall = rng.randi_range(data.overall.x, data.overall.y)
				player.potential = rng.randi_range(data.potential.x, data.potential.y)
				player.condition = config.initial_condition
				var contract = ContractModel.new()
				contract.id = world.career.allocate_id("contract")
				contract.kind = "athlete"
				contract.subject_id = player.id
				contract.club_id = club.id
				contract.salary = rng.randi_range(data.salary.x, data.salary.y)
				contract.end_season = rng.randi_range(config.contract_duration_range.x, config.contract_duration_range.y)
				player.contract_id = contract.id
				world.players[player.id] = player
				world.contracts[contract.id] = contract
	var employment = ContractModel.new()
	employment.id = world.career.allocate_id("contract")
	employment.kind = "employment"
	employment.subject_id = world.manager.id
	employment.club_id = initial_club_id
	world.manager.employment_contract_id = employment.id
	world.contracts[employment.id] = employment
	errors = world.validation_errors()
	return {"world": world if errors.is_empty() else null, "errors": errors}
