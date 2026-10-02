extends SceneTree
const Batch = preload("res://tests/simulation/match_batch_tests.gd")
var failed: int = 0
var passed: int = 0

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
	Batch.new().run(_check)
	print("Phase 4 standalone batch: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
