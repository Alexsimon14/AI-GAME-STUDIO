extends Node
## Sole session autoload. Phase 0 has no career/world state or gameplay.

const DEFAULT_CONFIG = preload("res://resources/config/bootstrap_config.tres")

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
