extends RefCounted
var _data: Dictionary = {}

func configure(data: Dictionary) -> void:
	if _data.is_empty(): _data = data.duplicate(true)

func snapshot() -> Dictionary:
	return _data.duplicate(true)
