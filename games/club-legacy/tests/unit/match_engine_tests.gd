extends RefCounted
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")
const Simulator = preload("res://scripts/domain/match/match_simulator.gd")
const Command = preload("res://scripts/domain/match/match_command.gd")
const Strength = preload("res://scripts/domain/match/team_strength_calculator.gd")
const Context = preload("res://scripts/domain/match/tactical_context.gd")
const Checkpoint = preload("res://scripts/persistence/match_checkpoint_codec.gd")
const Factory = preload("res://scripts/domain/services/world_factory.gd")
const Config = preload("res://resources/config/world_config.tres")
const Season = preload("res://scripts/domain/services/season_service.gd")
const Adapter = preload("res://scripts/application/fixture_match_adapter.gd")
const Envelope = preload("res://scripts/persistence/save_envelope.gd")
const Repository = preload("res://scripts/persistence/save_repository.gd")
const ResultModel = preload("res://scripts/domain/match/match_result.gd")

static func data(home_quality: float = 60.0, away_quality: float = 60.0, seed_value: int = 12345, formation: String = "4-4-2") -> Dictionary:
	var output := {"fixture_id": "fixture:test", "seed": seed_value, "engine_version": 1, "config": MatchInputModel.defaults()}
	for side in ["home", "away"]:
		var team := {"club_id": "club:" + side, "players": {}, "starters": [], "bench": [], "formation": formation, "tactic": "EQUILIBRADA"}
		var index: int = 0
		for position in ["GK", "DEF", "MID", "ATT"]:
			for n in range(MatchInputModel.FORMATIONS[formation][position]):
				var id: String = side + ":" + str(index)
				team.players[id] = {"position": position, "overall": home_quality if side == "home" else away_quality, "condition": 100.0}
				team.starters.append(id)
				index += 1
		for position in ["GK", "DEF", "DEF", "MID", "MID", "ATT", "ATT"]:
			var id: String = side + ":" + str(index)
			team.players[id] = {"position": position, "overall": home_quality if side == "home" else away_quality, "condition": 100.0}
			team.bench.append(id)
			index += 1
		output[side] = team
	return output

static func input_from(snapshot: Dictionary):
	var input = MatchInputModel.new()
	input.configure(snapshot)
	return input

static func canonical(value: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(value, "", true)), "", true)

static func coherent(result: Dictionary) -> bool:
	var counts := {"home": {"goals": 0, "chances": 0, "shots": 0, "on_target": 0}, "away": {"goals": 0, "chances": 0, "shots": 0, "on_target": 0}}
	var active := {"home": result.teams.home.starters.duplicate(), "away": result.teams.away.starters.duplicate()}
	# Reconstruct initial on-field IDs from the final squad and applied substitutions.
	for c in result.commands.duplicate():
		if c.kind == "SUBSTITUTE":
			active[c.side].erase(c.payload["in"])
			active[c.side].append(c.payload.out)
	var previous: int = 0
	for event in result.events:
		if event.minute < previous or event.minute < 1 or event.minute > 90: return false
		previous = event.minute
		if event.club_id.is_empty(): continue
		var side: String = "home" if event.club_id == result.home_club_id else "away"
		if event.club_id != result.home_club_id and event.club_id != result.away_club_id: return false
		if event.kind == "SUBSTITUTE":
			active[side].erase(event.context.out)
			active[side].append(event.context["in"])
		if event.kind == "CHANCE": counts[side].chances += 1
		if event.kind in ["GOAL", "SAVE", "SHOT_OFF_TARGET"]: counts[side].shots += 1
		if event.kind in ["GOAL", "SAVE"]: counts[side].on_target += 1
		if event.kind == "GOAL":
			counts[side].goals += 1
			if event.player_id not in active[side] or result.teams[side].players[event.player_id].position == "GK": return false
	for side in ["home", "away"]:
		var s: Dictionary = result.stats[side]
		if not (s.goals <= s.on_target and s.on_target <= s.shots and s.shots <= s.chances): return false
		for key in counts[side]:
			if counts[side][key] != s[key]: return false
	return result.minute == 90 and result.phase == "FINISHED" and result.stats.home.possession_ticks + result.stats.away.possession_ticks == 90

func run(check: Callable) -> void:
	var sim = Simulator.new()
	var original: Dictionary = data()
	var input = input_from(original)
	var frozen: Dictionary = input.snapshot()
	original.home.players["home:0"].overall = 0.0
	check.call(input.snapshot() == frozen, "MatchInput detached from source dictionaries")
	var queried: Dictionary = input.snapshot()
	queried.home.players.clear()
	check.call(input.snapshot() == frozen and not input.configure(data()).is_empty(), "MatchInput copy accessor and configure-once")
	var baseline: Dictionary = sim.simulate(input).result.snapshot()
	check.call(coherent(baseline), "Events, goal authors, score and stats coherent")
	var result_copy = sim.simulate(input).result
	var changed: Dictionary = result_copy.snapshot()
	changed.stats.home.goals = 999
	result_copy.configure(changed)
	check.call(result_copy.snapshot() == baseline, "MatchResult configure-once and copy accessor protect confirmed data")
	var object_data: Dictionary = data()
	object_data["live_reference"] = RefCounted.new()
	check.call(not MatchInputModel.new().configure(object_data).is_empty(), "Snapshot rejects live object references")
	check.call(not sim.start(42).errors.is_empty() and not sim.simulate(input, [42]).errors.is_empty(), "Invalid input/command objects return explicit errors")
	var identical: bool = true
	for n in range(100):
		identical = identical and sim.simulate(input).result.snapshot() == baseline
	check.call(identical, "100 repeats input/seed/config/version structurally identical")
	var variations: Dictionary = {}
	for seed_value in range(100):
		var result: Dictionary = sim.simulate(input_from(data(60, 60, seed_value))).result.snapshot()
		variations[str(result.stats.home.goals) + ":" + str(result.stats.away.goals)] = true
	check.call(variations.size() > 1, "Different seeds permit different scores")
	for formation in MatchInputModel.FORMATIONS:
		check.call(coherent(sim.simulate(input_from(data(60, 60, 42, formation))).result.snapshot()), "Valid formation simulated " + formation)
	for invalid in ["short", "long", "duplicate", "no-gk", "formation", "position", "missing", "overall", "condition", "tactic", "seed", "same-club", "same-player", "fixture", "bench", "version", "config"]:
		var broken: Dictionary = data()
		match invalid:
			"short": broken.home.starters.pop_back()
			"long": broken.home.starters.append(broken.home.bench[0])
			"duplicate": broken.home.starters[1] = broken.home.starters[0]
			"no-gk": broken.home.players["home:0"].position = "ATT"
			"formation": broken.home.formation = "4-3-3"
			"position": broken.home.players["home:1"].position = "LD"
			"missing": broken.home.players.erase("home:1")
			"overall": broken.home.players["home:1"].overall = -1
			"condition": broken.home.players["home:1"].condition = 101
			"tactic": broken.home.tactic = "SUPER"
			"seed": broken.seed = "42"
			"same-club": broken.away.club_id = broken.home.club_id
			"same-player": broken.away.players["home:0"] = broken.home.players["home:0"]
			"fixture": broken.fixture_id = ""
			"bench": broken.home.bench.append("extra")
			"version": broken.engine_version = 99
			"config": broken.config.home_initiative = 9.0
		check.call(not MatchInputModel.new().configure(broken).is_empty(), "Invalid match input rejected: " + invalid)
	var calculator = Strength.new()
	var low: Dictionary = data().home
	var normal: Dictionary = calculator.calculate(low)
	for p in low.players.values(): p.condition = 25.0
	var reduced: Dictionary = calculator.calculate(low)
	check.call(reduced.attack < normal.attack and reduced.defense < normal.defense and reduced.midfield < normal.midfield and reduced.keeper < normal.keeper, "Condition reduces all effective sectors")
	var offensive: Dictionary = Context.compose(normal, "OFENSIVA")
	var cautious: Dictionary = Context.compose(normal, "CAUTELOSA")
	check.call(offensive.attack > normal.attack and offensive.cover < normal.defense and offensive.effort > 1, "Offensive support/exposure/fatigue trade-off")
	check.call(cautious.attack < normal.attack and cautious.cover > normal.defense, "Cautious attack/cover trade-off")
	var state = sim.start(input).state
	var formation_command := {"id": "reshape", "minute": 0, "side": "home", "kind": "FORMATION", "payload": {"formation": "4-3-3", "starters": state.teams.home.starters.duplicate()}}
	check.call(sim.command(state, formation_command).errors.is_empty() and state.teams.home.substitutions == 0, "Formation changes same eleven without consuming substitutions")
	var role_counts := {"GK": 0, "DEF": 0, "MID": 0, "ATT": 0}
	for role in state.teams.home.roles.values(): role_counts[role] += 1
	check.call(role_counts == MatchInputModel.FORMATIONS["4-3-3"], "Formation assigns broad field roles and applies inadequacy penalty")
	var strength_roles: Dictionary = calculator.calculate(state.teams.home)
	check.call(strength_roles.attack < 90.0 and strength_roles.midfield == 45.0, "Out-of-position role uses documented 0.65 contribution")
	check.call(not sim.command(state, {"id": "malformed-formation", "minute": 0, "side": "home", "kind": "FORMATION", "payload": {"formation": "5-3-2", "starters": [42]}}).errors.is_empty(), "Malformed formation IDs rejected without sort exception")
	check.call(not sim.command(state, {"id": "gk-outfield", "minute": 0, "side": "home", "kind": "SUBSTITUTE", "payload": {"out": "home:1", "in": "home:11"}}).errors.is_empty(), "Goalkeeper cannot replace outfield player")
	sim.advance(state)
	check.call(sim.command(state, formation_command).idempotent, "Applied command retry remains idempotent after advancing")
	state = sim.start(input).state
	var codec = Checkpoint.new()
	for minute in [0, 23, 45, 75]:
		while state.minute < minute: sim.advance(state)
		var rng_before: int = state.rng.state
		for n in range(20):
			state.view()
			calculator.calculate(state.teams.home)
		check.call(state.rng.state == rng_before, "Queries preserve RNG at minute " + str(minute))
		var encoded: Dictionary = codec.encode(state)
		var restored: Dictionary = codec.decode(JSON.parse_string(JSON.stringify(encoded)))
		check.call(restored.errors.is_empty() and canonical(restored.state.view()) == canonical(state.view()), "Checkpoint restores events/state/RNG minute " + str(minute))
		state = restored.state
	while state.minute < 90: sim.advance(state)
	check.call(canonical(sim.result(state).snapshot()) == canonical(baseline), "Incremental + resumed equals uninterrupted batch")
	check.call(not sim.advance(state).errors.is_empty() and sim.result(sim.start(input).state) == null, "Full-time advance rejected and unfinished result unavailable")
	var commands: Array = []
	state = sim.start(input).state
	while state.minute < 45: sim.advance(state)
	var history: Array = state.events.duplicate(true)
	for n in range(3):
		var c = Command.new()
		c.id = "sub:" + str(n)
		c.minute = 45
		c.kind = "SUBSTITUTE"
		c.payload = {"out": "home:" + str(n + 1), "in": "home:" + str(12 + n)}
		# Reserve 14 is MID, so third replaces a midfielder instead of DEF.
		if n == 2: c.payload.out = "home:5"
		commands.append(c.snapshot())
		check.call(sim.command(state, c.snapshot()).errors.is_empty(), "Substitution accepted " + str(n + 1))
		check.call(sim.command(state, c.snapshot()).idempotent and state.teams.home.substitutions == n + 1, "Substitution replay idempotent " + str(n + 1))
	check.call(not sim.command(state, {"id": "fourth", "minute": 45, "side": "home", "kind": "SUBSTITUTE", "payload": {"out": "home:6", "in": "home:15"}}).errors.is_empty(), "Fourth substitution rejected")
	var tactical := {"id": "attack", "minute": 45, "side": "home", "kind": "TACTIC", "payload": {"tactic": "OFENSIVA"}}
	commands.append(tactical)
	check.call(sim.command(state, tactical).errors.is_empty(), "Tactic changes at valid boundary")
	check.call(state.events.slice(0, history.size()) == history, "Commands never rewrite past events")
	var restored_command: Dictionary = codec.decode(JSON.parse_string(JSON.stringify(codec.encode(state))))
	check.call(restored_command.errors.is_empty(), "Checkpoint preserves substitutions/tactic/ordered commands")
	state = restored_command.state
	while state.minute < 90: sim.advance(state)
	var commanded: Dictionary = sim.result(state).snapshot()
	check.call(canonical(commanded) == canonical(sim.simulate(input, commands).result.snapshot()) and coherent(commanded), "Replay commands equals resumed incremental and valid goal authors")
	check.call(sim.command(state, tactical).idempotent, "Applied tactic retry remains idempotent after full time")
	check.call(state.teams.home.players["home:1"].condition > state.teams.home.players["home:12"].condition, "Removed player stops wearing down, incoming contributes")
	var corrupted: Dictionary = codec.encode(state)
	corrupted.rng_state = "0"
	check.call(not codec.decode(corrupted).errors.is_empty(), "Corrupt RNG checkpoint rejected")
	corrupted = codec.encode(state)
	corrupted.resolved.events[0].kind = "GOAL"
	check.call(not codec.decode(corrupted).errors.is_empty(), "Corrupt resolved events rejected")
	var large_seed = input_from(data(60, 60, 9223372036854775807))
	var large_state = sim.start(large_seed).state
	sim.advance(large_state)
	check.call(codec.decode(JSON.parse_string(JSON.stringify(codec.encode(large_state)))).state.input.seed == 9223372036854775807, "Checkpoint preserves int64 maximum seed exactly")
	_integration(check)

func _integration(check: Callable) -> void:
	var world = Factory.new().create(Config, 777, "Manager", "MEDIO", "match-tests").world
	Season.new().create(world)
	var fixture_id: String = ""
	for fixture in world.fixtures.values():
		if fixture.round == 1:
			fixture_id = fixture.id
			break
	var adapter = Adapter.new()
	check.call(not adapter.submit(world, ResultModel.new(), "empty").errors.is_empty(), "Empty MatchResult rejected without exception")
	check.call(not adapter.submit(world, RefCounted.new(), "wrong").errors.is_empty(), "Wrong MatchResult type rejected")
	var input = adapter.build(world, fixture_id, 444).input
	var source_condition: int = world.players[input.snapshot().home.starters[0]].condition
	var sim = Simulator.new()
	var state = sim.start(input).state
	for n in range(31): sim.advance(state)
	world.active_match = Checkpoint.new().encode(state)
	var alien: Dictionary = world.active_match.duplicate(true)
	# Internally valid match with the right clubs but foreign athletes is not a valid career checkpoint.
	var alien_data: Dictionary = data()
	alien_data.fixture_id = fixture_id
	alien_data.home.club_id = world.fixtures[fixture_id].home_club_id
	alien_data.away.club_id = world.fixtures[fixture_id].away_club_id
	alien = Checkpoint.new().encode(sim.start(input_from(alien_data)).state)
	check.call(not Checkpoint.new().validate_world(world, alien).is_empty(), "Checkpoint rejects athletes outside career roster")
	var path: String = "user://phase4_tests_" + str(Time.get_ticks_usec())
	var repo = Repository.new(path)
	check.call(repo.save_world(world).errors.is_empty(), "Active match snapshot saved via schema 3 A/B repository")
	var loaded: Dictionary = repo.load_world()
	check.call(loaded.errors.is_empty() and loaded.world.active_match != null, "Active match loaded from real JSON save")
	check.call(repo.save_world(world).revision == 2, "Active checkpoint receives next snapshot revision")
	var incompatible_path: String = path.path_join("b.json")
	var original_text: String = FileAccess.get_file_as_string(incompatible_path)
	var incompatible: Dictionary = JSON.parse_string(original_text)
	incompatible.payload.active_match.match_engine_version = "99"
	incompatible.checksum = Envelope.new().checksum(incompatible)
	var writer = FileAccess.open(incompatible_path, FileAccess.WRITE)
	writer.store_string(JSON.stringify(incompatible))
	writer.close()
	check.call(repo.load_world().recovered and not repo.save_world(world).errors.is_empty(), "Incompatible match checkpoint falls back but cannot be overwritten")
	check.call(FileAccess.get_file_as_string(incompatible_path) == JSON.stringify(incompatible), "Future match checkpoint file preserved untouched")
	writer = FileAccess.open(incompatible_path, FileAccess.WRITE)
	writer.store_string(original_text)
	writer.close()
	state = Checkpoint.new().decode(loaded.world.active_match).state
	world = loaded.world
	while state.minute < 90: sim.advance(state)
	var result = sim.result(state)
	check.call(result.snapshot() == sim.simulate(input).result.snapshot(), "Real disk resume identical to atomic match")
	check.call(world.players[input.snapshot().home.starters[0]].condition == source_condition, "Simulator never mutates WorldState athlete condition")
	world.active_match = null
	check.call(adapter.submit(world, result, "match-result").errors.is_empty(), "Thin adapter submits result without Season depending on motor")
	check.call(adapter.submit(world, result, "match-result").idempotent, "Match result retry preserves Season idempotence")
	check.call(repo.save_world(world).errors.is_empty() and repo.load_world().world.fixtures[fixture_id].status == "COMPLETED", "Confirmed match persists with schema 3")
	var envelope = Envelope.new()
	var old: Dictionary = JSON.parse_string(envelope.pack(world, 3).text)
	old.schema_version = 2
	old.save_version = "phase-3-v1"
	old.payload.erase("active_match")
	old.checksum = envelope.checksum(old)
	var migrated: Dictionary = envelope.unpack(JSON.stringify(old))
	check.call(migrated.errors.is_empty() and migrated.migrated and migrated.world.active_match == null and migrated.world.fixtures[fixture_id].status == "COMPLETED", "Schema 2 -> 3 preserves competition and adds no invented match")
	for file in ["a.json", "b.json", "snapshot.tmp"]:
		var full: String = ProjectSettings.globalize_path(path.path_join(file))
		if FileAccess.file_exists(full): DirAccess.remove_absolute(full)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check.call(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(path)), "Phase 4 isolated test save files cleaned")
