extends RefCounted

var id: String = ""
var seed: int = 0
var manager_id: String = ""
var next_entity_serial: int = 1
var config_snapshot: Dictionary = {}

func allocate_id(kind: String) -> String:
	var value := "%s:%s:%d" % [id, kind, next_entity_serial]
	next_entity_serial += 1
	return value
