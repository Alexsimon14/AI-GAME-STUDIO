extends RefCounted
## Initial career aggregate. No SceneTree, persistence, or gameplay dependencies.

var career: RefCounted
var manager: RefCounted
var clubs: Dictionary = {}
var players: Dictionary = {}
var contracts: Dictionary = {}
var leagues: Dictionary = {}
var selected_profile: String = ""

func roster_ids(club_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	for contract in contracts.values():
		if contract.active and contract.kind == "athlete" and contract.club_id == club_id:
			result.append(contract.subject_id)
	result.sort()
	return result

func payroll(club_id: String) -> int:
	var total: int = 0
	for contract in contracts.values():
		if contract.active and contract.kind == "athlete" and contract.club_id == club_id:
			total += contract.salary
	return total

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if career == null or manager == null:
		errors.append("Career and manager are required.")
		return errors
	if clubs.size() != 12 or leagues.size() != 2 or players.size() != 216:
		errors.append("Initial world requires 12 clubs, 2 leagues and 216 players.")
	var ids: Dictionary = {}
	for entity in [career, manager]:
		if entity.id.is_empty() or ids.has(entity.id):
			errors.append("Duplicate/empty entity ID.")
		ids[entity.id] = true
	for collection in [clubs, players, contracts, leagues]:
		for key in collection:
			var entity = collection[key]
			if key != entity.id or entity.id.is_empty() or ids.has(entity.id):
				errors.append("Invalid/duplicate entity ID: " + str(key))
			ids[entity.id] = true
	if career.manager_id != manager.id:
		errors.append("Career manager link is invalid.")
	var division_counts: Dictionary = {}
	for league_id in leagues:
		division_counts[league_id] = 0
	for club in clubs.values():
		if not leagues.has(club.league_id):
			errors.append("Unknown division.")
		else:
			division_counts[club.league_id] += 1
		var roster := roster_ids(club.id)
		if roster.size() != 18:
			errors.append("Club must have 18 athletes: " + club.id)
		var coverage := {"GK": 0, "DEF": 0, "MID": 0, "ATT": 0}
		for player_id in roster:
			if players.has(player_id) and coverage.has(players[player_id].position):
				coverage[players[player_id].position] += 1
		if coverage.GK < 1 or coverage.DEF < 5 or coverage.MID < 4 or coverage.ATT < 3:
			errors.append("Insufficient formation coverage: " + club.id)
	for count in division_counts.values():
		if count != 6:
			errors.append("Division must have 6 clubs.")
	var active_subjects: Dictionary = {}
	var employment_count: int = 0
	for contract in contracts.values():
		if not clubs.has(contract.club_id):
			errors.append("Contract club does not exist.")
		if contract.end_season < 1 or contract.salary < 0:
			errors.append("Invalid contract terms.")
		if contract.kind == "athlete":
			if not players.has(contract.subject_id):
				errors.append("Contract athlete does not exist.")
			elif players[contract.subject_id].contract_id != contract.id:
				errors.append("Player contract link is inconsistent.")
		elif contract.kind == "employment":
			if contract.subject_id != manager.id or manager.employment_contract_id != contract.id or contract.salary != 0:
				errors.append("Invalid manager contract link.")
			if contract.active:
				employment_count += 1
				if clubs.has(contract.club_id) and clubs[contract.club_id].profile != selected_profile:
					errors.append("Initial employment does not match selected profile.")
		else:
			errors.append("Unknown contract kind.")
		if contract.active:
			if active_subjects.has(contract.subject_id):
				errors.append("Duplicate active contract/athlete ownership.")
			active_subjects[contract.subject_id] = contract.id
	if employment_count != 1 or not contracts.has(manager.employment_contract_id):
		errors.append("Manager requires exactly one initial employment.")
	for player in players.values():
		if not contracts.has(player.contract_id):
			errors.append("Player lacks contract.")
		else:
			var contract = contracts[player.contract_id]
			if not contract.active or contract.subject_id != player.id or contract.kind != "athlete":
				errors.append("Player lacks valid active athlete contract.")
		if player.position not in ["GK", "DEF", "MID", "ATT"] or player.age < 1 or player.overall < 0 or player.potential < player.overall or player.potential > 100 or player.condition < 1 or player.condition > 100:
			errors.append("Invalid athlete attributes.")
	return errors
