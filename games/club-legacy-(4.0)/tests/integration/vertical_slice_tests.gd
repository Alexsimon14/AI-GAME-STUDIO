extends RefCounted
const Flow = preload("res://scripts/application/career_flow.gd")
const Codec = preload("res://scripts/persistence/world_codec.gd")
const Simulator = preload("res://scripts/domain/match/match_simulator.gd")
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")
const Checkpoint = preload("res://scripts/persistence/match_checkpoint_codec.gd")
const Scene = preload("res://scenes/main.tscn")
const Factory = preload("res://scripts/domain/services/world_factory.gd")
const Config = preload("res://resources/config/world_config.tres")

func _play(flow) -> void:
	flow.set_paused(false)
	while flow.match_state != null:
		if flow.paused: flow.set_paused(false)
		if not flow.advance_match(): break

func _clean(path: String) -> void:
	for name in ["a.json", "b.json", "snapshot.tmp", "replacement.tmp", "replacement.pending", "previous-a.json", "previous-b.json"]:
		var file: String = path.path_join(name)
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if DirAccess.dir_exists_absolute(path): DirAccess.remove_absolute(path)

func run(check: Callable) -> void:
	var directory: String = "user://phase5_tests_" + str(Time.get_ticks_usec())
	var flow = Flow.new(directory)
	check.call(not flow.navigate("HOME") and flow.world == null, "Application rejects navigation without career")
	check.call(not flow.create_career(" ", "MEDIO", 123, "blank"), "Application rejects blank manager name")
	for profile in ["PEQUENO", "MEDIO", "ELITE"]:
		flow = Flow.new(directory)
		check.call(flow.create_career("Treinador", profile, 123, "slice-" + profile), "Application creates career profile " + profile)
		check.call(flow.world.clubs[flow.club_id()].profile == profile and flow.screen == "HOME", "Correct first club and Home " + profile)
		for screen in ["SQUAD", "LINEUP", "TABLE", "HOME"]: check.call(flow.navigate(screen), "Essential navigation " + profile + " " + screen)
		check.call(flow.set_lineup(flow.lineup.starters, flow.lineup.bench, "4-4-2", "EQUILIBRADA"), "Domain-valid lineup through application " + profile)
		check.call(flow.start_match() and flow.match_state.minute == 0 and flow.world.active_match != null, "Starts incremental match without instant finish " + profile)
		flow.set_paused(true)
		var frozen: Dictionary = flow.match_state.view()
		var rng_before: int = flow.match_state.rng.state
		flow.tick(120.0)
		check.call(flow.match_state.view() == frozen and flow.match_state.rng.state == rng_before, "Paused presentation preserves engine " + profile)
		_play(flow)
		check.call(flow.screen == "RESULT" and flow.world.season.current_round == 2 and flow.world.active_match == null, "Result and whole round committed " + profile)
		var first_results: int = 0
		for f in flow.world.fixtures.values():
			if f.status == "COMPLETED": first_results += 1
		check.call(first_results == 6, "Same engine closes all six matches " + profile)
		var before: Dictionary = Codec.new().encode(flow.world).payload
		check.call(flow.finish_round() and Codec.new().encode(flow.world).payload == before, "Repeated finish never duplicates score/round " + profile)
		check.call(flow.standings(flow.world.clubs[flow.club_id()].league_id).all(func(row): return row.played == 1), "Derived classification updates " + profile)
	flow = Flow.new(directory)
	flow.create_career("Manager", "MEDIO", 777, "flow-integration")
	var initial: Dictionary = flow.lineup.duplicate(true)
	var invalid: Array = initial.starters.duplicate()
	invalid.pop_back()
	check.call(not flow.set_lineup(invalid, initial.bench, "4-4-2", "EQUILIBRADA") and flow.lineup == initial, "Invalid ten-player lineup rejected without publishing")
	invalid = initial.starters.duplicate()
	invalid[1] = invalid[0]
	check.call(not flow.set_lineup(invalid, initial.bench, "4-4-2", "EQUILIBRADA"), "Duplicate player rejected through application")
	invalid = initial.starters.duplicate()
	invalid[0] = "foreign-player"
	check.call(not flow.set_lineup(invalid, initial.bench, "4-4-2", "EQUILIBRADA"), "Foreign player rejected through application")
	for formation in ["4-4-2", "4-3-3", "5-3-2"]:
		check.call(flow.suggest_lineup(formation, "CAUTELOSA") and flow.set_lineup(flow.lineup.starters, flow.lineup.bench, formation, "CAUTELOSA"), "Suggested formation domain-valid " + formation)
	flow.suggest_lineup("4-4-2", "EQUILIBRADA")
	check.call(flow.save() and flow.notice == "JOGO SALVO", "Explicit SaveRepository save with feedback")
	flow = null
	flow = Flow.new(directory)
	check.call(flow.can_continue() and flow.load_career() and flow.screen == "HOME" and flow.world.manager.name == "Manager", "Destroy session -> load -> continue Home")
	flow.navigate("SQUAD")
	flow.navigate("LINEUP")
	flow.start_match()
	for n in range(12): flow.advance_match()
	check.call(flow.navigate("HOME") and flow.paused and flow.navigate("MATCH"), "Leaving match pauses presentation; returns same active match")
	check.call(flow.match_command("TACTIC", {"tactic": "OFENSIVA"}), "Application sends existing tactical command")
	var team: Dictionary = flow.match_state.teams.home if flow.match_state.teams.home.club_id == flow.club_id() else flow.match_state.teams.away
	check.call(flow.match_command("FORMATION", {"formation": "4-3-3", "starters": team.starters.duplicate()}), "Application sends existing formation command")
	team = flow.match_state.teams.home if flow.match_state.teams.home.club_id == flow.club_id() else flow.match_state.teams.away
	var outgoing: String = ""
	var incoming: String = ""
	for id in team.starters:
		if team.players[id].position == "DEF": outgoing = id; break
	for id in team.bench:
		if team.players[id].position == "DEF": incoming = id; break
	check.call(flow.match_command("SUBSTITUTE", {"out": outgoing, "in": incoming}), "Application sends existing substitution command")
	check.call(flow.save(), "Save active match and applied commands")
	var expected: Dictionary = Checkpoint.new().encode(flow.match_state)
	flow = null
	flow = Flow.new(directory)
	check.call(flow.load_career() and flow.screen == "MATCH" and flow.paused, "Active match reload resumes at saved point paused")
	check.call(JSON.stringify(Checkpoint.new().encode(flow.match_state)) == JSON.stringify(expected), "Resume preserves seed/RNG/minute/events/commands")
	_play(flow)
	check.call(flow.world.season.current_round == 2 and flow.last_result != null, "Resumed match confirms round once")
	for n in range(2):
		flow.navigate("HOME")
		flow.start_match()
		_play(flow)
	check.call(flow.world.season.current_round == 4 and flow.world.validation_errors().is_empty(), "Three consecutive rounds remain valid")
	check.call(flow.save() and flow.save(), "Successive explicit A/B saves")
	var older: Dictionary = flow.repository.load_world()
	var newest_slot: String = older.slot
	var corrupt = FileAccess.open(directory.path_join(newest_slot), FileAccess.WRITE)
	corrupt.store_string("corrupt")
	corrupt.close()
	check.call(flow.load_career() and flow.notice.contains("Uma versão anterior válida foi recuperada"), "A/B fallback communicated in plain language")
	var namespace_before: String = flow.world.career.id
	check.call(not flow.create_career("New", "ELITE", 888, "replacement"), "New career requires explicit replacement confirmation")
	# Restore usable A/B set through the normal writer before replacement tests.
	flow.save()
	check.call(flow.create_career("New", "ELITE", 888, "replacement", true), "Confirmed new career accepted")
	flow.repository.failure_stage = "after_replace_removal"
	check.call(not flow.save() and flow.repository.load_world().world.career.id == namespace_before, "Replacement I/O seam rolls back prior career")
	flow.repository.failure_stage = ""
	check.call(flow.save() and flow.repository.load_world().world.manager.name == "New", "Confirmed replacement publishes only after explicit save")
	# Simulate the gap after originals were removed: backups remain the recovery source.
	for name in ["a.json", "b.json"]:
		if FileAccess.file_exists(directory.path_join(name)): DirAccess.remove_absolute(directory.path_join(name))
	var marker = FileAccess.open(directory.path_join("replacement.pending"), FileAccess.WRITE)
	marker.store_string("interrupted replacement")
	marker.close()
	check.call(flow.repository.load_world().recovered and not flow.repository.replace_world(flow.world).errors.is_empty(), "Interrupted replacement recovers archive and forbids overwriting recovery")
	check.call(flow.load_career() and flow.save() and not FileAccess.file_exists(directory.path_join("replacement.pending")), "Explicit save completes replacement recovery")
	_clean(directory)
	check.call(not DirAccess.dir_exists_absolute(directory), "Phase 5 isolated integration saves cleaned")
	_speed_tests(check)
	_ui_tests(check, directory + "_ui")

func _speed_tests(check: Callable) -> void:
	var results: Array = []
	for speed in [1, 2, 4]:
		var flow = Flow.new("user://phase5_speed_unused")
		flow.create_career("Speed", "MEDIO", 909, "speed-equality")
		flow.start_match()
		flow.set_speed(speed)
		var half_time: bool = false
		while flow.match_state != null:
			flow.tick(0.75)
			if flow.match_state != null and flow.paused:
				half_time = flow.match_state.phase == "HALF_TIME"
				flow.set_paused(false)
		check.call(half_time, "Interval pauses at minute 45 at " + str(speed) + "x")
		results.append(flow.last_result.snapshot())
	check.call(results[0] == results[1] and results[1] == results[2], "1x/2x/4x produce identical sporting result/events/stats")

func _ui_tests(check: Callable, directory: String) -> void:
	var tree = Engine.get_main_loop()
	var session = tree.root.get_node("GameSession")
	var old_flow = session.flow
	session.flow = Flow.new(directory)
	var main = Scene.instantiate()
	tree.root.add_child(main)
	check.call(main.get_node("ScreenHost").get_child_count() == 1 and main.find_child("ManagerName", true, false) != null, "Native Start screen instantiated under ScreenHost")
	check.call(session.act("create_career", ["UI", "PEQUENO", 321, "ui-test"]), "GameSession coordinates creation without business rules")
	for screen in ["SQUAD", "LINEUP", "TABLE", "HOME"]:
		check.call(session.act("navigate", [screen]) and main.get_node("ScreenHost").get_child_count() == 1, "ScreenHost replaces screen " + screen)
	check.call(session.act("start_match") and main.find_child("PauseMatch", true, false) != null and main.find_child("MatchEvents", true, false) != null, "Native Match controls and events instantiated")
	session.flow.set_paused(true)
	main.update_match()
	check.call(main.match_labels.clock.text.contains("PAUSADO"), "Match projection displays paused state")
	_play(session.flow)
	session.changed.emit()
	check.call(main.find_child("ContinueResult", true, false) != null, "Native Result screen has Continue action")
	main.free()
	session.flow = old_flow
	_clean(directory)
