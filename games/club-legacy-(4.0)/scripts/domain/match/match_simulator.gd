extends RefCounted
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")
const State = preload("res://scripts/domain/match/match_state.gd")
const Event = preload("res://scripts/domain/match/match_event.gd")
const Result = preload("res://scripts/domain/match/match_result.gd")
const Strength = preload("res://scripts/domain/match/team_strength_calculator.gd")
const Context = preload("res://scripts/domain/match/tactical_context.gd")
const Generator = preload("res://scripts/domain/match/chance_generator.gd")
const Resolver = preload("res://scripts/domain/match/chance_resolver.gd")
const ENGINE_VERSION: int = 1
var _strength = Strength.new()
var _generator = Generator.new()
var _resolver = Resolver.new()

func start(input) -> Dictionary:
	if input == null or not input is RefCounted or input.get_script() != MatchInputModel: return _error("Expected MatchInput.")
	var data: Dictionary = input.snapshot()
	var errors: PackedStringArray = MatchInputModel.validate(data)
	if not errors.is_empty(): return {"state": null, "errors": errors}
	var state = State.new()
	state.input = data.duplicate(true)
	state.rng.seed = data.seed
	for side in ["home", "away"]:
		state.teams[side] = data[side].duplicate(true)
		state.teams[side]["substitutions"] = 0
		state.teams[side]["removed"] = []
		state.teams[side]["roles"] = _roles(state.teams[side])
		state.stats[side] = {"goals": 0, "chances": 0, "clear_chances": 0, "shots": 0, "on_target": 0, "possession_ticks": 0}
	_emit(state, "START", "", "", {})
	return {"state": state, "errors": PackedStringArray()}

func advance(state) -> Dictionary:
	if state == null or state.phase == "FINISHED": return _error("Match is already finished/missing.")
	# One indivisible minute. No clocks, timers or global random state.
	if state.phase == "HALF_TIME": state.phase = "SECOND_HALF"
	state.minute += 1
	var home: Dictionary = Context.compose(_strength.calculate(state.teams.home), state.teams.home.tactic)
	var away: Dictionary = Context.compose(_strength.calculate(state.teams.away), state.teams.away.tactic)
	var initiative: float = (home.creation + 10.0) / (home.creation + away.creation + 20.0)
	initiative = clampf(initiative + float(state.input.config.home_initiative), 0.05, 0.95)
	var side: String = "home" if state.rng.randf() < initiative else "away"
	state.stats[side].possession_ticks += 1
	var offense: Dictionary = home if side == "home" else away
	var defense: Dictionary = away if side == "home" else home
	var chance: Dictionary = _generator.generate(offense, defense, state.rng, state.input.config.opportunity_rate)
	if not chance.is_empty():
		state.stats[side].chances += 1
		if chance.category == "CLEAR": state.stats[side].clear_chances += 1
		_emit(state, "CHANCE", state.teams[side].club_id, "", chance)
		var resolution: Dictionary = _resolver.resolve(chance, state.teams[side], defense, state.rng)
		if resolution.kind != "CHANCE_LOST": state.stats[side].shots += 1
		if resolution.kind in ["GOAL", "SAVE"]: state.stats[side].on_target += 1
		if resolution.kind == "GOAL": state.stats[side].goals += 1
		_emit(state, resolution.kind, state.teams[side].club_id, resolution.player_id, chance)
	for team_side in ["home", "away"]:
		var team: Dictionary = state.teams[team_side]
		var context: Dictionary = home if team_side == "home" else away
		for id in team.starters:
			team.players[id].condition = maxf(0.0, float(team.players[id].condition) - float(state.input.config.fatigue_per_minute) * context.effort)
	if state.minute == 45:
		state.phase = "HALF_TIME"
		_emit(state, "HALF_TIME", "", "", {})
	elif state.minute == 90:
		state.phase = "FINISHED"
		_emit(state, "END", "", "", {})
	return {"errors": PackedStringArray()}

func command(state, command_data: Dictionary) -> Dictionary:
	if state == null: return _error("Missing match state.")
	for key in ["id", "minute", "side", "kind", "payload"]:
		if not command_data.has(key): return _error("Incomplete command.")
	if not command_data.id is String or command_data.id.is_empty() or not command_data.minute is int or command_data.side not in ["home", "away"] or not command_data.payload is Dictionary: return _error("Invalid command boundary/side/ID.")
	for applied in state.commands:
		if applied.id == command_data.id:
			return {"errors": PackedStringArray(), "idempotent": true} if applied == command_data else _error("Command ID conflict.")
	if state.phase == "FINISHED" or command_data.minute != state.minute: return _error("Command outside a live boundary.")
	var team: Dictionary = state.teams[command_data.side]
	var candidate: Dictionary = team.duplicate(true)
	var payload: Dictionary = command_data.payload
	match command_data.kind:
		"TACTIC":
			if payload.get("tactic") not in MatchInputModel.TACTICS: return _error("Invalid tactic command.")
			candidate.tactic = payload.tactic
		"FORMATION":
			if payload.get("formation") not in MatchInputModel.FORMATIONS or not payload.get("starters") is Array: return _error("Invalid formation command.")
			var before: Array = team.starters.duplicate()
			var after: Array = payload.starters.duplicate()
			for id in after:
				if not id is String or id not in before: return _error("Invalid formation player ID.")
			before.sort()
			after.sort()
			if before != after: return _error("Formation cannot introduce a new player.")
			candidate.formation = payload.formation
			candidate.starters = payload.starters.duplicate()
			candidate.roles = _roles(candidate)
		"SUBSTITUTE":
			if candidate.substitutions >= 3 or payload.get("out") not in candidate.starters or payload.get("in") not in candidate.bench: return _error("Invalid substitution or limit reached.")
			candidate.starters[candidate.starters.find(payload.out)] = payload["in"]
			candidate.bench.erase(payload["in"])
			candidate.removed.append(payload.out)
			candidate.substitutions += 1
			if payload.has("formation"): candidate.formation = payload.formation
			if candidate.formation not in MatchInputModel.FORMATIONS: return _error("Invalid substitution formation.")
			candidate.roles = _roles(candidate)
		_:
			return _error("Unknown command.")
	var errors: PackedStringArray = MatchInputModel.validate_team(candidate)
	if not errors.is_empty(): return {"errors": errors}
	state.teams[command_data.side] = candidate
	state.commands.append(command_data.duplicate(true))
	_emit(state, command_data.kind, candidate.club_id, str(payload.get("in", "")), payload)
	return {"errors": PackedStringArray(), "idempotent": false}

func simulate(input, commands: Array = []) -> Dictionary:
	var previous: int = 0
	for scheduled in commands:
		if not scheduled is Dictionary or not scheduled.get("minute") is int or scheduled.minute < previous or scheduled.minute < 0 or scheduled.minute >= 90: return {"result": null, "errors": PackedStringArray(["Invalid/out-of-order scheduled command."])}
		previous = scheduled.minute
	var created: Dictionary = start(input)
	if not created.errors.is_empty(): return {"result": null, "errors": created.errors}
	var state = created.state
	var index: int = 0
	while state.phase != "FINISHED":
		while index < commands.size() and commands[index].get("minute") == state.minute:
			var applied: Dictionary = command(state, commands[index])
			if not applied.errors.is_empty(): return {"result": null, "errors": applied.errors}
			index += 1
		advance(state)
	if index != commands.size(): return {"result": null, "errors": PackedStringArray(["Unapplied/out-of-order command."])}
	return {"result": result(state), "errors": PackedStringArray()}

func result(state):
	if state == null or state.phase != "FINISHED": return null
	var data: Dictionary = state.view()
	data["fixture_id"] = state.input.fixture_id
	data["engine_version"] = ENGINE_VERSION
	data["seed"] = str(state.input.seed)
	data["config"] = state.input.config.duplicate(true)
	data["home_club_id"] = state.teams.home.club_id
	data["away_club_id"] = state.teams.away.club_id
	data["winner"] = "DRAW" if state.stats.home.goals == state.stats.away.goals else (state.teams.home.club_id if state.stats.home.goals > state.stats.away.goals else state.teams.away.club_id)
	data["summary"] = []
	for side in ["home", "away"]:
		data.stats[side]["possession_percent"] = float(state.stats[side].possession_ticks) * 100.0 / 90.0
		data.summary.append({"club_id": state.teams[side].club_id, "chances": state.stats[side].chances, "clear_chances": state.stats[side].clear_chances, "shots": state.stats[side].shots})
	var output = Result.new()
	output.configure(data)
	return output

func _emit(state, kind: String, club_id: String, player_id: String, context: Dictionary) -> void:
	state.events.append(Event.record(state.events.size() + 1, maxi(1, state.minute), kind, club_id, player_id, context))

func _roles(team: Dictionary) -> Dictionary:
	var roles: Dictionary = {}
	var remaining: Dictionary = MatchInputModel.FORMATIONS[team.formation].duplicate()
	# Preserve natural roles where possible; deterministically fill remaining slots.
	for id in team.starters:
		var position: String = team.players[id].position
		if remaining[position] > 0:
			roles[id] = position
			remaining[position] -= 1
	for id in team.starters:
		if roles.has(id): continue
		for position in ["GK", "DEF", "MID", "ATT"]:
			if remaining[position] > 0:
				roles[id] = position
				remaining[position] -= 1
				break
	return roles

func _error(reason: String) -> Dictionary:
	return {"state": null, "errors": PackedStringArray([reason])}
