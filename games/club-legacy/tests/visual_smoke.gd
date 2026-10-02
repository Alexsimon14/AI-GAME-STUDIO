extends SceneTree
## Real rendered viewport smoke; no mouse coordinates, production saves or success claims about manual clicks.
const Flow = preload("res://scripts/application/career_flow.gd")
const Main = preload("res://scenes/main.tscn")
const Factory = preload("res://scripts/domain/services/world_factory.gd")
const WorldConfig = preload("res://resources/config/world_config.tres")
const FinanceConfig = preload("res://resources/config/finance_config.gd")
const Finance = preload("res://scripts/domain/finance/finance_service.gd")
const Season = preload("res://scripts/domain/services/season_service.gd")
var directory: String = "user://phase5_visual_smoke_save"
var captures: String

func _initialize() -> void:
	call_deferred("_run")

func _capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var file: String = captures.path_join(name + ".png")
	var code: int = root.get_texture().get_image().save_png(file)
	print("VISUAL_CAPTURE ", name, " EXIT=", code, " PATH=", file)
	if code != OK: quit(1)

func _run() -> void:
	captures = OS.get_environment("TEMP").path_join("club-legacy-phase51-visual")
	DirAccess.make_dir_recursive_absolute(captures)
	_cleanup()
	var session = root.get_node("GameSession")
	session.flow = Flow.new(directory)
	var main = Main.instantiate()
	root.add_child(main)
	await _capture("01-start")
	main.find_child("ManagerName", true, false).text = "Alex"
	main.find_child("StartCareer", true, false).pressed.emit()
	await _capture("02-home")
	main.action("navigate", ["FINANCES"])
	await _capture("02c-finances-initial")
	main.action("navigate", ["HOME"])
	main._shell.scroll.scroll_vertical = 1000
	await _capture("02b-home-detail")
	main.action("navigate", ["SQUAD"])
	await _capture("03-squad")
	main.action("navigate", ["LINEUP"])
	await _capture("04-lineup")
	main._shell.scroll.scroll_vertical = 1000
	await _capture("04b-bench")
	main.action("suggest_lineup", ["4-3-3", "EQUILIBRADA"])
	await _capture("04c-433")
	main.action("suggest_lineup", ["5-3-2", "EQUILIBRADA"])
	await _capture("04d-532")
	main.action("suggest_lineup", ["4-4-2", "EQUILIBRADA"])
	main.find_child("PlayMatch", true, false).pressed.emit()
	for n in range(20): session.flow.advance_match()
	session.flow.set_paused(true)
	main.update_match()
	await _capture("05-match-paused")
	main.action("save")
	main.action("navigate", ["START"])
	await _capture("05b-active-preview")
	var content_height: float = main._shell.scroll.get_child(0).get_combined_minimum_size().y
	print("START_VIEWPORT_1100 content=", content_height, " available=", main._shell.scroll.size.y)
	if content_height > main._shell.scroll.size.y + 1:
		printerr("START_VIEWPORT overflow in 1100x780")
		quit(1)
		return
	root.content_scale_size = Vector2i(860, 650)
	root.size = Vector2i(860, 650)
	await _capture("05c-start-narrow")
	root.content_scale_size = Vector2i(1100, 780)
	root.size = Vector2i(1100, 780)
	main.action("load_career")
	await _capture("06-match-loaded")
	while session.flow.match_state != null:
		session.flow.set_paused(false)
		if not session.flow.advance_match():
			printerr("VISUAL_SMOKE failure: ", session.flow.last_errors)
			quit(1)
			return
	session.changed.emit()
	await _capture("07-result")
	main.action("navigate", ["TABLE"])
	await _capture("08-table")
	main.action("save")
	main.action("load_career")
	await _capture("09-home-loaded")
	main.action("navigate", ["FINANCES"])
	await _capture("09b-finances-round-positive")
	main._shell.scroll.scroll_vertical = 1000
	await _capture("09c-finances-ledger")
	main.action("navigate", ["HOME"])
	root.content_scale_size = Vector2i(860, 650)
	root.size = Vector2i(860, 650)
	await _capture("10-home-narrow")
	main.action("navigate", ["FINANCES"])
	await _capture("10b-finances-narrow")
	main.action("navigate", ["HOME"])
	main.action("navigate", ["LINEUP"])
	await _capture("11-lineup-narrow")
	main._shell.scroll.scroll_vertical = 1000
	await _capture("12-bench-narrow")
	main.action("navigate", ["TABLE"])
	await _capture("13-table-narrow")
	main.action("navigate", ["LINEUP"])
	main.find_child("PlayMatch", true, false).pressed.emit()
	session.flow.set_paused(true)
	main.update_match()
	await _capture("14-match-narrow")
	# Separate deterministic TEST fixture for a deficit; no direct cash edit.
	var preserved_world = session.flow.world
	var preserved_match = session.flow.match_state
	var negative = Factory.new().create(WorldConfig, 602, "Teste de déficit", "PEQUENO", "visual-phase6-deficit").world
	Season.new().create(negative)
	var config = FinanceConfig.new()
	config.ticket_price = 0
	config.maintenance_per_round = {"PEQUENO": 200000, "MEDIO": 200000, "ELITE": 200000}
	Finance.new().initialize(negative, config)
	for fixture in negative.fixtures.values():
		if fixture.round == 1: Season.new().submit_result(negative, fixture.id, 1, 1, "visual-deficit:" + fixture.id)
	Season.new().commit_round(negative, 1, "visual-deficit-round")
	var accounted: Dictionary = Finance.new().process_round(negative, 1)
	if not accounted.errors.is_empty():
		printerr("VISUAL_SMOKE financial failure: ", accounted.errors)
		quit(1)
		return
	session.flow.world = negative
	session.flow.match_state = null
	main.action("navigate", ["FINANCES"])
	await _capture("15-finances-negative-narrow")
	root.content_scale_size = Vector2i(1100, 780)
	root.size = Vector2i(1100, 780)
	await _capture("16-finances-negative-wide")
	session.flow.world = preserved_world
	session.flow.match_state = preserved_match
	print("VISUAL_SMOKE rendered wide/narrow screens; OWNER VISUAL CHECK REQUIRED")
	_cleanup()
	quit(0)

func _cleanup() -> void:
	for name in ["a.json", "b.json", "snapshot.tmp"]:
		var file: String = directory.path_join(name)
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if DirAccess.dir_exists_absolute(directory): DirAccess.remove_absolute(directory)
