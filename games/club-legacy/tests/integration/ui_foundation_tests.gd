extends RefCounted
const Flow = preload("res://scripts/application/career_flow.gd")
const Scene = preload("res://scenes/main.tscn")
const Dashboard = preload("res://ui/dashboard_projection.gd")
const Identity = preload("res://ui/club_identity.gd")
const Checkpoint = preload("res://scripts/persistence/match_checkpoint_codec.gd")
const Codec = preload("res://scripts/persistence/world_codec.gd")

func run(check: Callable) -> void:
	var directory: String = "user://phase51_ui_tests_" + str(Time.get_ticks_usec())
	var tree = Engine.get_main_loop()
	var session = tree.root.get_node("GameSession")
	var previous = session.flow
	session.flow = Flow.new(directory)
	var main = Scene.instantiate()
	tree.root.add_child(main)
	check.call(main.find_child("AppShell", true, false) != null and main.find_child("Sidebar", true, false) != null and main.find_child("TopBar", true, false) != null, "5.1 stable shell/sidebar/topbar constructed")
	var sidebar = main.find_child("Sidebar", true, false)
	check.call(main.find_child("ManagerName", true, false) != null and main.find_child("StartCareer", true, false) != null, "5.1 new-career controls retained")
	check.call(main._shell.nav.HOME.disabled and main._shell.nav.save.disabled, "5.1 career commands unavailable before creation")
	check.call(main.session.act("create_career", ["Owner", "PEQUENO", 180, "ui-foundation"]), "5.1 career created through unchanged application")
	var flow = session.flow
	var before: Dictionary = Codec.new().encode(flow.world).payload
	var data: Dictionary = Dashboard.build(flow)
	check.call(data.roster_count == 18 and data.condition == 100 and data.highlights.size() == 2, "5.1 roster summary uses world values")
	check.call(data.recent.is_empty() and data.upcoming.size() == 4 and data.performance.played == 0, "5.1 initial Home has no fabricated results")
	check.call(data.standings == flow.standings(flow.world.clubs[flow.club_id()].league_id), "5.1 Home standings match canonical calculator")
	check.call(Codec.new().encode(flow.world).payload == before, "5.1 presentation queries do not mutate career")
	for club in flow.world.clubs.values():
		var identity: Dictionary = Identity.get_identity(club)
		check.call(Identity.CATALOG.has(club.name) and identity.abbreviation.length() >= 2 and identity.primary != identity.secondary, "5.1 original identity for " + club.name)
	check.call(main.find_child("NextMatchCard", true, false) != null and main.find_child("PrepareMatch", true, false) != null, "5.1 dominant next fixture and prepare action")
	main.find_child("PrepareMatch", true, false).pressed.emit()
	check.call(flow.screen == "LINEUP" and flow.match_state == null, "5.1 preparation never skips lineup review")
	for formation in ["4-4-2", "4-3-3", "5-3-2"]:
		main.action("suggest_lineup", [formation, "EQUILIBRADA"])
		var pitch = main.find_child("TacticalPitch", true, false)
		var parts: PackedStringArray = formation.split("-")
		check.call(pitch.slot_ids.size() == 11 and pitch.line_counts == [int(parts[2]), int(parts[1]), int(parts[0]), 1], "5.1 static pitch follows " + formation)
		check.call(main.find_child("BenchPanel", true, false) != null, "5.1 bench separate from pitch " + formation)
	main.action("suggest_lineup", ["4-4-2", "EQUILIBRADA"])
	var player_out: String = flow.lineup.starters[0]
	var replacement: String = ""
	for id in flow.lineup.bench:
		if flow.world.players[id].position == flow.world.players[player_out].position: replacement = id; break
	var lineup_view = main._views._lineup_view
	lineup_view.selected_id = player_out
	lineup_view.swap(replacement)
	check.call(replacement in flow.lineup.starters and player_out in flow.lineup.bench, "5.1 field-to-bench swap uses application validation")
	var starters: Array = flow.lineup.starters.duplicate()
	lineup_view = main._views._lineup_view
	lineup_view.selected_id = replacement
	var foreign_position: String = ""
	for id in flow.lineup.bench:
		if flow.world.players[id].position != flow.world.players[replacement].position: foreign_position = id; break
	lineup_view.swap(foreign_position)
	check.call(flow.lineup.starters == starters and not flow.last_errors.is_empty(), "5.1 invalid visual swap does not alter lineup")
	main._dialog.hide()
	main.action("navigate", ["LINEUP"])
	main.find_child("PlayMatch", true, false).pressed.emit()
	check.call(flow.screen == "MATCH" and main.find_child("MatchEvents", true, false) != null, "5.1 match central starts from existing control")
	var input = flow.match_state.input.duplicate(true)
	for i in range(25): flow.advance_match()
	flow.set_paused(true)
	main.update_match()
	check.call(main.match_labels.clock.text.contains("PAUSADO") and main.match_labels.speeds.has(4), "5.1 clear pause and speed controls")
	var events = main.match_labels.events
	var out_menu = main.match_labels.out_players
	main.action("set_speed", [4])
	check.call(main.match_labels.events == events and main.match_labels.out_players == out_menu, "5.1 incremental UI retains menus and event controls")
	flow.set_paused(false)
	main.show_message("Mensagem de teste")
	check.call(flow.paused, "5.1 modal attention pauses active match")
	main._dialog.hide()
	check.call(main.action("save"), "5.1 unchanged writer saves active match")
	var checkpoint: Dictionary = Checkpoint.new().encode(flow.match_state)
	main.action("navigate", ["START"])
	check.call(main.find_child("ContinueCareer", true, false) != null and flow.screen == "START", "5.1 saved active-match preview offers resume")
	main.find_child("ContinueCareer", true, false).pressed.emit()
	check.call(flow.screen == "MATCH" and flow.paused and Checkpoint.new().encode(flow.match_state) == checkpoint, "5.1 resume preview retains full active checkpoint")
	check.call(flow.match_state.input == input, "5.1 identity/theme does not modify simulation input")
	while flow.match_state != null:
		flow.set_paused(false)
		flow.advance_match()
	session.changed.emit()
	check.call(main.find_child("ContinueResult", true, false) != null, "5.1 sporting result offers continuation")
	main.find_child("ContinueResult", true, false).pressed.emit()
	data = Dashboard.build(flow)
	check.call(data.performance.played == 1 and data.recent.size() == 1 and data.upcoming[0].round == 2, "5.1 Home updates real results/performance/calendar")
	check.call(main.find_child("Sidebar", true, false) == sidebar, "5.1 sidebar persists through navigation and matches")
	main.action("navigate", ["TABLE"])
	check.call(main.find_child("StandingsTable", true, false) != null and flow.world.season.current_round == 2, "5.1 full standings presentation preserves season state")
	main.free()
	session.flow = previous
	for filename in ["a.json", "b.json", "snapshot.tmp"]:
		if FileAccess.file_exists(directory.path_join(filename)): DirAccess.remove_absolute(directory.path_join(filename))
	if DirAccess.dir_exists_absolute(directory): DirAccess.remove_absolute(directory)
	check.call(not DirAccess.dir_exists_absolute(directory), "5.1 isolated UI saves cleaned")
