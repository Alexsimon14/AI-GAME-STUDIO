extends SceneTree
## Run with: godot --headless --path games/club-legacy --script res://tests/run_tests.gd

const ConfigScript = preload("res://resources/config/bootstrap_config.gd")
const SessionScript = preload("res://scripts/application/game_session.gd")
const MainScene = preload("res://scenes/main.tscn")
const DefaultConfig = preload("res://resources/config/bootstrap_config.tres")
const WorldTests = preload("res://tests/unit/world_model_tests.gd")
const PersistenceTests = preload("res://tests/integration/persistence_tests.gd")

var _passed: int = 0
var _failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, description: String) -> void:
	if condition:
		_passed += 1
		print("PASS: ", description)
	else:
		_failed += 1
		printerr("FAIL: ", description)

func _run() -> void:
	_check(DefaultConfig.validation_errors().is_empty(), "Default TEST / PLACEHOLDER config accepted")
	var invalid = ConfigScript.new()
	invalid.schema_version = 99
	_check(invalid.validation_errors().size() == 3, "Invalid schema, empty ID and purpose rejected")
	var session = SessionScript.new()
	_check(session.initialize(DefaultConfig), "GameSession initializes without SceneTree")
	_check(session.is_initialized(), "Valid session reports initialized")
	_check(not session.initialize(invalid), "Invalid config rejected by session")
	_check(not session.is_initialized(), "Rejected initialization leaves session unavailable")
	_check(not session.initialize(null), "Missing config rejected")
	_check(not session.initialize(Resource.new()), "Wrong resource type rejected")
	_check(session.initialize(DefaultConfig), "Session can recover using valid config")
	session.free()
	var autoload = root.get_node_or_null("GameSession")
	_check(autoload != null, "Project creates GameSession autoload")
	if autoload != null:
		_check(autoload.call("is_initialized"), "Autoload accepts default configuration")
	var main = MainScene.instantiate()
	_check(main is Control, "Main scene loads as Control")
	_check(main.get_node_or_null("ScreenHost") is Control, "Main owns ScreenHost")
	_check(main.get_node_or_null("DialogLayer") is CanvasLayer, "Main owns DialogLayer")
	main.free()
	print("Phase 0: %d passed, %d failed" % [_passed, _failed])
	WorldTests.new().run(_check)
	print("Phase 0 + Phase 1: %d passed, %d failed" % [_passed, _failed])
	PersistenceTests.new().run(_check)
	if "--force-failure" in OS.get_cmdline_user_args():
		_check(false, "Intentional runner failure probe")
	print("Phase 0 + Phase 1 + Phase 2: %d passed, %d failed" % [_passed, _failed])
	quit(0 if _failed == 0 else 1)
