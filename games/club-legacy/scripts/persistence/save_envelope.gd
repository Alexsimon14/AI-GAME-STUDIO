extends RefCounted

const Codec = preload("res://scripts/persistence/world_codec.gd")
const SeasonService = preload("res://scripts/domain/services/season_service.gd")
const SCHEMA_VERSION: int = 2
const SAVE_VERSION: String = "phase-3-v1"
const ENGINE_VERSION: String = "4.7.2.stable.official.ed1daf0bf"

func pack(world, revision: int) -> Dictionary:
	if revision < 1:
		return {"text": "", "errors": PackedStringArray(["Invalid revision."])}
	var encoded: Dictionary = Codec.new().encode(world)
	if not encoded.errors.is_empty():
		return {"text": "", "errors": encoded.errors}
	var envelope := {"schema_version": SCHEMA_VERSION, "save_version": SAVE_VERSION,
		"engine_version": ENGINE_VERSION, "revision": str(revision), "payload": encoded.payload}
	envelope["checksum"] = checksum(envelope)
	return {"text": JSON.stringify(envelope, "", true), "errors": PackedStringArray()}

## SHA-256 over JSON-normalized, sorted-key compact fields except checksum.
func checksum(envelope: Dictionary) -> String:
	var protected_fields: Dictionary = envelope.duplicate(true)
	protected_fields.erase("checksum")
	# JSON parser represents numbers as floats. Normalize on both sides so schema
	# integer 1 and parsed 1.0 produce the same protected bytes. Large ints are strings.
	var normalized = JSON.parse_string(JSON.stringify(protected_fields, "", true))
	return JSON.stringify(normalized, "", true).sha256_text()

func unpack(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return failure("Invalid/truncated JSON.")
	var data = parser.data
	if not data is Dictionary:
		return failure("Envelope must be an object.")
	for field in ["schema_version", "save_version", "engine_version", "revision", "checksum", "payload"]:
		if not data.has(field):
			return failure("Missing envelope field: " + field)
	if not (data.schema_version is int or data.schema_version is float) or (data.schema_version != 1 and data.schema_version != SCHEMA_VERSION):
		return failure("Unsupported schema; migration unavailable.")
	var expected_version: String = "phase-2-v1" if data.schema_version == 1 else SAVE_VERSION
	if data.save_version != expected_version or not data.engine_version is String:
		return failure("Unsupported save metadata.")
	var codec = Codec.new()
	if not codec.valid_integer(data.revision) or int(data.revision) < 1:
		return failure("Invalid revision.")
	if not data.checksum is String or data.checksum != checksum(data):
		return failure("Checksum mismatch.")
	var migration: Dictionary = migrate(data)
	if not migration.errors.is_empty(): return failure(migration.errors[0])
	data = migration.envelope
	var decoded: Dictionary = codec.decode(data.payload)
	if not decoded.errors.is_empty():
		return {"world": null, "revision": 0, "errors": decoded.errors}
	return {"world": decoded.world, "revision": int(data.revision), "errors": PackedStringArray(), "migrated": migration.migrated}

## Called only after original envelope checksum/version validation.
func migrate(data: Dictionary) -> Dictionary:
	if data.schema_version == SCHEMA_VERSION:
		return {"envelope": data, "migrated": false, "errors": PackedStringArray()}
	if data.schema_version != 1:
		return {"errors": PackedStringArray(["Unsupported schema; migration unavailable."])}
	var codec = Codec.new()
	var legacy: Dictionary = codec.decode(data.payload, true)
	if not legacy.errors.is_empty(): return {"errors": legacy.errors}
	var created: Dictionary = SeasonService.new().create(legacy.world)
	if not created.errors.is_empty(): return {"errors": created.errors}
	var encoded: Dictionary = codec.encode(legacy.world)
	if not encoded.errors.is_empty(): return {"errors": encoded.errors}
	var updated: Dictionary = data.duplicate(true)
	updated.schema_version = SCHEMA_VERSION
	updated.save_version = SAVE_VERSION
	updated.payload = encoded.payload
	updated.checksum = checksum(updated)
	return {"envelope": updated, "migrated": true, "errors": PackedStringArray()}

func failure(reason: String) -> Dictionary:
	return {"world": null, "revision": 0, "errors": PackedStringArray([reason])}
