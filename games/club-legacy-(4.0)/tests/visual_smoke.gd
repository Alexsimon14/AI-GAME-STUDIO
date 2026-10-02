extends SceneTree
## Real rendered viewport smoke; no mouse coordinates, production saves or success claims about manual clicks.
const Flow = preload("res://scripts/application/career_flow.gd")
const Main = preload("res://scenes/main.tscn")
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
	captures = OS.get_environment("TEMP").path_join("club-legacy-phase5-visual")
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
	main.action("navigate", ["SQUAD"])
	await _capture("03-squad")
	main.action("navigate", ["LINEUP"])
	await _capture("04-lineup")
	main.find_child("PlayMatch", true, false).pressed.emit()
	for n in range(20): session.flow.advance_match()
	session.flow.set_paused(true)
	main.update_match()
	await _capture("05-match-paused")
	main.action("save")
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
	print("VISUAL_SMOKE rendered 9 screens; actual pointer/keyboard interaction remains OWNER CHECK REQUIRED")
	_cleanup()
	quit(0)

func _cleanup() -> void:
	for name in ["a.json", "b.json", "snapshot.tmp"]:
		var file: String = directory.path_join(name)
		if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	if DirAccess.dir_exists_absolute(directory): DirAccess.remove_absolute(directory)
