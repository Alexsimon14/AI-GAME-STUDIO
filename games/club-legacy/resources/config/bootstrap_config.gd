extends Resource
## Bootstrap metadata only. No gameplay/balance parameters.

@export var schema_version: int = 1
@export var config_id: String = ""
@export var purpose: String = ""

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if schema_version != 1:
		errors.append("Unsupported bootstrap schema_version.")
	if config_id.strip_edges().is_empty():
		errors.append("config_id is required.")
	if purpose != "TEST / PLACEHOLDER":
		errors.append("Bootstrap purpose must be TEST / PLACEHOLDER.")
	return errors
