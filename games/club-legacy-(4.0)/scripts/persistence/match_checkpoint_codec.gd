extends RefCounted
## Explicit checkpoint v1. Replay validates saved events/state, not a new outcome.
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")
const Simulator = preload("res://scripts/domain/match/match_simulator.gd")
const ENGINE = "4.7.2.stable.official.ed1daf0bf"

func encode(state) -> Dictionary:
	var input: Dictionary = state.input.duplicate(true)
	input.seed = str(input.seed)
	var commands: Array = state.commands.duplicate(true)
	for c in commands: c.minute = str(c.minute)
	return {"checkpoint_version": "1", "engine_version": ENGINE, "match_engine_version": "1", "input": input, "minute": str(state.minute), "rng_state": str(state.rng.state), "commands": commands, "resolved": state.view()}

func decode(data: Variant) -> Dictionary:
	if not data is Dictionary or data.get("checkpoint_version") != "1" or data.get("engine_version") != ENGINE or data.get("match_engine_version") != "1": return _error("Unsupported match checkpoint/engine.")
	for key in ["input", "minute", "rng_state", "commands", "resolved"]:
		if not data.has(key): return _error("Missing checkpoint field.")
	if not data.input is Dictionary or not data.commands is Array or data.commands.size() > 128 or not data.resolved is Dictionary: return _error("Invalid checkpoint shape.")
	if not _integer(data.minute) or int(data.minute) < 0 or int(data.minute) > 90 or not _integer(data.rng_state) or not _integer(data.input.get("seed")): return _error("Invalid checkpoint integer.")
	var input_data: Dictionary = data.input.duplicate(true)
	input_data.seed = int(input_data.seed)
	var input = MatchInputModel.new()
	var errors: PackedStringArray = input.configure(input_data)
	if not errors.is_empty(): return {"state": null, "errors": errors}
	var sim = Simulator.new()
	var state = sim.start(input).state
	var index: int = 0
	while true:
		while index < data.commands.size():
			var c = data.commands[index]
			if not c is Dictionary or not _integer(c.get("minute")): return _error("Invalid saved command.")
			if int(c.minute) != state.minute: break
			var command: Dictionary = c.duplicate(true)
			command.minute = int(command.minute)
			var applied: Dictionary = sim.command(state, command)
			if not applied.errors.is_empty(): return _error("Invalid command replay.")
			index += 1
		if state.minute == int(data.minute): break
		sim.advance(state)
	if index != data.commands.size() or str(state.rng.state) != data.rng_state or _canonical(state.view()) != _canonical(data.resolved): return _error("Checkpoint replay/state mismatch.")
	# Seed was initialized before reproducing/restoring the saved state.
	state.rng.state = int(data.rng_state)
	return {"state": state, "errors": PackedStringArray()}

func validate_world(world, checkpoint: Variant) -> PackedStringArray:
	if checkpoint == null: return PackedStringArray()
	var decoded: Dictionary = decode(checkpoint)
	if not decoded.errors.is_empty(): return decoded.errors
	var data: Dictionary = decoded.state.input
	if not world.fixtures.has(data.fixture_id): return PackedStringArray(["Active match fixture missing."])
	var f = world.fixtures[data.fixture_id]
	if f.status == "COMPLETED" or world.season == null or f.round != world.season.current_round or data.home.club_id != f.home_club_id or data.away.club_id != f.away_club_id: return PackedStringArray(["Active match relationship invalid."])
	for side in ["home", "away"]:
		var roster: PackedStringArray = world.roster_ids(data[side].club_id)
		for id in data[side].players:
			if not world.players.has(id) or id not in roster or data[side].players[id].position != world.players[id].position: return PackedStringArray(["Active match athlete identity/membership invalid."])
	return PackedStringArray()

func _integer(value: Variant) -> bool:
	return value is String and value.is_valid_int() and str(int(value)) == value

func _canonical(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value, "", true)), "", true)

func _error(reason: String) -> Dictionary:
	return {"state": null, "errors": PackedStringArray([reason])}
