extends RefCounted
## One logical career; two physical snapshots. No UI or SceneTree dependency.

const Envelope = preload("res://scripts/persistence/save_envelope.gd")
const MAX_BYTES: int = 8 * 1024 * 1024
var directory: String
var failure_stage: String = "" # Test seam, never set by player/UI.

func _init(storage_directory: String = "user://club_legacy_save") -> void:
	directory = storage_directory

func _path(name: String) -> String:
	return directory.path_join(name)

func _allowed_path() -> bool:
	return directory.begins_with("user://") and not ".." in directory and directory != "user://"

func has_snapshots() -> bool:
	return FileAccess.file_exists(_path("a.json")) or FileAccess.file_exists(_path("b.json")) or FileAccess.file_exists(_path("replacement.pending"))

func load_world() -> Dictionary:
	if not _allowed_path():
		return _error("Save directory must be a dedicated user:// directory.")
	var candidates: Array = []
	var diagnostics := PackedStringArray()
	var existing: int = 0
	var slots: Array = ["a.json", "b.json"]
	var replacement_recovery: bool = not FileAccess.file_exists(_path("a.json")) and not FileAccess.file_exists(_path("b.json")) and FileAccess.file_exists(_path("replacement.pending"))
	if replacement_recovery: slots = ["previous-a.json", "previous-b.json"]
	for slot in slots:
		if not FileAccess.file_exists(_path(slot)):
			continue
		existing += 1
		var result: Dictionary = _read(slot)
		if result.errors.is_empty():
			result["slot"] = slot
			candidates.append(result)
		else:
			diagnostics.append(slot + ": " + str(result.errors))
	if candidates.is_empty():
		return _error("No snapshots." if existing == 0 else "No valid snapshots: " + str(diagnostics))
	if candidates.size() == 2:
		if candidates[0].world.career.id != candidates[1].world.career.id:
			return _error("Snapshot career identities disagree.")
		if candidates[0].revision == candidates[1].revision:
			return _error("Ambiguous duplicate snapshot revision.")
	var newest: Dictionary = candidates[0]
	for candidate in candidates:
		if candidate.revision > newest.revision:
			newest = candidate
	newest["recovered"] = replacement_recovery or not diagnostics.is_empty()
	newest["diagnostics"] = diagnostics
	return newest

## Only called after explicit new-career replacement confirmation, never by load.
## Stage/validate new data first; retain previous snapshots and rollback on I/O error.
func replace_world(world) -> Dictionary:
	if not _allowed_path(): return _error("Invalid replacement directory.")
	if FileAccess.file_exists(_path("replacement.pending")): return _error("Recover and save the previous career before replacement.")
	var envelope = Envelope.new()
	var packed: Dictionary = envelope.pack(world, 1)
	if not packed.errors.is_empty(): return packed
	if not envelope.unpack(packed.text).errors.is_empty(): return _error("Invalid replacement world.")
	if failure_stage == "before_replace": return _error("Injected replacement failure.")
	if DirAccess.make_dir_recursive_absolute(directory) != OK: return _error("Cannot create replacement directory.")
	var staged: String = _path("replacement.tmp")
	if not _write_text(staged, packed.text): return _error("Cannot stage replacement.")
	if not envelope.unpack(FileAccess.get_file_as_string(staged)).errors.is_empty(): return _error("Invalid staged replacement.")
	var originals: Dictionary = {}
	for slot in ["a.json", "b.json"]:
		if FileAccess.file_exists(_path(slot)):
			var read: Dictionary = _read(slot)
			if not read.errors.is_empty(): return _error("Cannot replace unreadable/incompatible save.")
			originals[slot] = FileAccess.get_file_as_string(_path(slot))
			var backup: String = _path("previous-" + slot)
			if not _write_text(backup, originals[slot]) or FileAccess.get_file_as_string(backup) != originals[slot]: return _error("Cannot preserve previous save.")
		elif FileAccess.file_exists(_path("previous-" + slot)):
			DirAccess.remove_absolute(_path("previous-" + slot))
	if not _write_text(_path("replacement.pending"), "previous snapshots retained"): return _error("Cannot mark replacement.")
	for slot in originals:
		if DirAccess.remove_absolute(_path(slot)) != OK:
			_restore_replacement(originals)
			return _error("Cannot replace previous snapshot.")
	if failure_stage == "after_replace_removal" or DirAccess.rename_absolute(staged, _path("a.json")) != OK:
		_restore_replacement(originals)
		return _error("Cannot publish replacement.")
	var checked: Dictionary = _read("a.json")
	if not checked.errors.is_empty():
		DirAccess.remove_absolute(_path("a.json"))
		_restore_replacement(originals)
		return _error("Replacement validation failed.")
	DirAccess.remove_absolute(_path("replacement.pending"))
	return {"errors": PackedStringArray(), "revision": 1}

func _restore_replacement(originals: Dictionary) -> void:
	var restored: bool = true
	for slot in originals: restored = _write_text(_path(slot), originals[slot]) and restored
	if restored: DirAccess.remove_absolute(_path("replacement.pending"))
	if FileAccess.file_exists(_path("replacement.tmp")): DirAccess.remove_absolute(_path("replacement.tmp"))

func _write_text(path: String, content: String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null: return false
	file.store_string(content)
	file.flush()
	var result: bool = file.get_error() == OK
	file.close()
	return result

func save_world(world) -> Dictionary:
	if not _allowed_path():
		return _error("Invalid save directory.")
	var previous: Dictionary = load_world()
	var has_snapshot: bool = FileAccess.file_exists(_path("a.json")) or FileAccess.file_exists(_path("b.json")) or (previous.errors.is_empty() and previous.get("recovered", false))
	if has_snapshot and not previous.errors.is_empty():
		return _error("Refusing to overwrite unreadable snapshots: " + str(previous.errors))
	if has_snapshot and previous.world.career.id != world.career.id:
		return _error("Refusing to replace a different career.")
	# Never overwrite a version we cannot interpret, even if the other slot loads.
	for slot in ["a.json", "b.json"]:
		if FileAccess.file_exists(_path(slot)):
			var inspected: Dictionary = _read(slot)
			for reason in inspected.errors:
				if reason.begins_with("Unsupported schema") or reason.begins_with("Unsupported save metadata") or reason.begins_with("Unsupported match") or reason.begins_with("Unsupported Match Engine"):
					return _error("Refusing to overwrite an incompatible save version.")
	if has_snapshot and previous.revision == 9223372036854775807:
		return _error("Revision exhausted.")
	var revision: int = previous.revision + 1 if has_snapshot else 1
	var target: String = "b.json" if has_snapshot and previous.slot == "a.json" else "a.json"
	var envelope = Envelope.new()
	var packed: Dictionary = envelope.pack(world, revision)
	if not packed.errors.is_empty():
		return {"world": null, "revision": 0, "errors": packed.errors}
	# Validate encoded schema/config as well as domain before writing anything.
	var checked: Dictionary = envelope.unpack(packed.text)
	if not checked.errors.is_empty():
		return checked
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return _error("Cannot create save directory.")
	var temporary: String = _path("snapshot.tmp")
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _error("Cannot open temporary save.")
	file.store_string(packed.text)
	file.flush()
	var write_error: int = file.get_error()
	file.close()
	if write_error != OK:
		return _abort("Failed writing temporary save.")
	var temp_result: Dictionary = _read("snapshot.tmp")
	if not temp_result.errors.is_empty() or temp_result.revision != revision:
		return _abort("Temporary save validation failed.")
	if failure_stage in ["after_temp", "before_promote"]:
		return _abort("Injected save failure: " + failure_stage)
	# Delete only inactive target; current validated snapshot remains untouched.
	if FileAccess.file_exists(_path(target)) and DirAccess.remove_absolute(_path(target)) != OK:
		return _abort("Cannot replace inactive snapshot.")
	if failure_stage == "after_target_removal":
		return _abort("Injected save failure after removing inactive target.")
	if DirAccess.rename_absolute(temporary, _path(target)) != OK:
		return _abort("Cannot promote temporary snapshot.")
	var promoted: Dictionary = _read(target)
	if not promoted.errors.is_empty():
		return _error("Promoted snapshot failed validation; previous snapshot retained.")
	promoted["slot"] = target
	if FileAccess.file_exists(_path("replacement.pending")): DirAccess.remove_absolute(_path("replacement.pending"))
	return promoted

func _read(name: String) -> Dictionary:
	var file := FileAccess.open(_path(name), FileAccess.READ)
	if file == null:
		return _error("Cannot read snapshot.")
	if file.get_length() > MAX_BYTES:
		file.close()
		return _error("Snapshot exceeds size limit.")
	var text: String = file.get_as_text()
	var read_error: int = file.get_error()
	file.close()
	if read_error != OK and read_error != ERR_FILE_EOF:
		return _error("Snapshot read failed.")
	return Envelope.new().unpack(text)

func _abort(reason: String) -> Dictionary:
	if FileAccess.file_exists(_path("snapshot.tmp")):
		DirAccess.remove_absolute(_path("snapshot.tmp"))
	return _error(reason)

func _error(reason: String) -> Dictionary:
	return {"world": null, "revision": 0, "errors": PackedStringArray([reason])}
