extends Node
## Sole session autoload, explicit application coordinator; football remains in domain.

const DEFAULT_CONFIG = preload("res://resources/config/bootstrap_config.tres")
const Flow = preload("res://scripts/application/career_flow.gd")
signal changed
var flow: RefCounted = Flow.new()

func act(method: String, arguments: Array = []) -> bool:
	if method not in ["create_career", "navigate", "suggest_lineup", "set_lineup", "start_match", "set_speed", "match_command", "finish_round", "save", "load_career"]: return false
	var success: bool = flow.callv(method, arguments)
	changed.emit()
	return success

func _process(delta: float) -> void:
	if flow.tick(delta): changed.emit()

var _initialized: bool = false
var _configuration_errors := PackedStringArray()

func _ready() -> void:
	if not initialize(DEFAULT_CONFIG):
		push_error("Club Legacy bootstrap configuration rejected: %s" % _configuration_errors)

func initialize(configuration: Resource) -> bool:
	_initialized = false
	_configuration_errors = PackedStringArray()
	if configuration == null:
		_configuration_errors.append("Bootstrap configuration is missing.")
	elif configuration.get_script() != DEFAULT_CONFIG.get_script():
		_configuration_errors.append("Unexpected bootstrap configuration resource.")
	else:
		_configuration_errors = configuration.call("validation_errors")
	_initialized = _configuration_errors.is_empty()
	return _initialized

func is_initialized() -> bool:
	return _initialized

func configuration_errors() -> PackedStringArray:
	return _configuration_errors.duplicate()
