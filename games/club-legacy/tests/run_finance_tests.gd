extends SceneTree
const Tests = preload("res://tests/integration/finance_tests.gd")
var passed: int = 0
var failed: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, description: String) -> void:
	if ok:
		passed += 1
		print("PASS: ", description)
	else:
		failed += 1
		printerr("FAIL: ", description)

func _run() -> void:
	Tests.new().run(_check)
	print("Phase 6 focused: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
