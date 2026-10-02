extends RefCounted

const Codec = preload("res://scripts/persistence/world_codec.gd")
const Envelope = preload("res://scripts/persistence/save_envelope.gd")
const Repository = preload("res://scripts/persistence/save_repository.gd")
const Factory = preload("res://scripts/domain/services/world_factory.gd")
const Config = preload("res://resources/config/world_config.tres")
const WorldTests = preload("res://tests/unit/world_model_tests.gd")

func run(check: Callable) -> void:
	var world = Factory.new().create(Config, 9223372036854775807, "Treinador Ção", "ELITE", "persistence-test").world
	world.players.values()[0].condition = 51
	var codec = Codec.new()
	var envelope = Envelope.new()
	var encoded: Dictionary = codec.encode(world)
	check.call(encoded.errors.is_empty(), "Phase 2 explicit serializer accepts WorldState")
	var expected: Dictionary = WorldTests.new().structure(world)
	var text: String = JSON.stringify(encoded.payload)
	var decoded: Dictionary = codec.decode(JSON.parse_string(text))
	check.call(decoded.errors.is_empty(), "Deserialize JSON payload")
	if decoded.world == null:
		return
	check.call(WorldTests.new().structure(decoded.world) == expected, "Full structural JSON round-trip including effective config")
	check.call(decoded.world.career.seed == 9223372036854775807, "64-bit seed precision preserved")
	check.call(decoded.world.career.next_entity_serial == world.career.next_entity_serial, "ID counter preserved")
	check.call(decoded.world.career.id == world.career.id, "Career namespace preserved")
	check.call(decoded.world.contracts[decoded.world.manager.employment_contract_id].club_id == world.contracts[world.manager.employment_contract_id].club_id, "Employment preserved")
	check.call(decoded.world.career.allocate_id("player") == world.career.allocate_id("player"), "ID allocation resumes identically after load")
	# Recreate expected after allocating counter, and release original to test reconstruction.
	expected = WorldTests.new().structure(world)
	var packed: Dictionary = envelope.pack(world, 1)
	world = null
	var round_trip: Dictionary = envelope.unpack(packed.text)
	if not round_trip.errors.is_empty():
		printerr("Round-trip diagnostics: ", round_trip.errors)
		check.call(false, "Envelope round-trip required for repository tests")
		return
	check.call(round_trip.errors.is_empty() and WorldTests.new().structure(round_trip.world) == expected, "Load reconstructs released in-memory state without WorldFactory")
	var generation_config: Resource = Config
	var current_config: Dictionary = generation_config.call("snapshot")
	generation_config.set("manager_reputation", 12)
	var independent: Dictionary = envelope.unpack(packed.text)
	check.call(independent.world.manager.reputation == 70 and independent.world.career.config_snapshot.manager_reputation == 70, "Load does not depend on current generation config")
	generation_config.set("manager_reputation", current_config.manager_reputation)
	var data: Dictionary = JSON.parse_string(packed.text)
	check.call(envelope.unpack("{").world == null, "Invalid JSON rejected")
	check.call(envelope.unpack(packed.text.left(packed.text.length() / 2)).world == null, "Truncated JSON rejected")
	for field in ["schema_version", "payload", "checksum", "revision"]:
		var missing: Dictionary = data.duplicate(true)
		missing.erase(field)
		check.call(envelope.unpack(JSON.stringify(missing)).world == null, "Missing envelope field rejected: " + field)
	var future: Dictionary = data.duplicate(true)
	future.schema_version = 99
	future.checksum = envelope.checksum(future)
	check.call(envelope.unpack(JSON.stringify(future)).world == null, "Future schema explicitly rejected")
	var corrupt: Dictionary = data.duplicate(true)
	corrupt.payload.manager.name = "Alterado"
	check.call(envelope.unpack(JSON.stringify(corrupt)).world == null, "Payload corruption detected by checksum")
	var revision_edit: Dictionary = data.duplicate(true)
	revision_edit.revision = "1000"
	check.call(envelope.unpack(JSON.stringify(revision_edit)).world == null, "Revision metadata protected by checksum")
	for variant in ["reference", "duplicate", "type", "missing", "count", "contract", "counter", "config"]:
		var bad: Dictionary = data.duplicate(true)
		match variant:
			"reference": bad.payload.contracts[0].club_id = "missing"
			"duplicate": bad.payload.players[1].id = bad.payload.players[0].id
			"type": bad.payload.players[0].age = []
			"missing": bad.payload.players[0].erase("condition")
			"count": bad.payload.clubs.pop_back()
			"contract": bad.payload.players[0].contract_id = bad.payload.players[1].contract_id
			"counter": bad.payload.career.next_entity_serial = "1"
			"config": bad.payload.career.config_snapshot.erase("profiles")
		bad.checksum = envelope.checksum(bad)
		check.call(envelope.unpack(JSON.stringify(bad)).world == null, "Rechecksummed invalid structure rejected: " + variant)
	var root_path: String = "user://phase2_tests_" + str(Time.get_ticks_usec())
	var repository = Repository.new(root_path)
	check.call(repository.load_world().world == null, "Repository without files returns explicit error")
	var first: Dictionary = repository.save_world(round_trip.world)
	check.call(first.errors.is_empty() and first.revision == 1 and first.slot == "a.json", "Initial save revision 1 in slot A")
	check.call(repository.load_world().revision == 1, "Written snapshot can be read")
	round_trip.world.manager.name = "Revisão dois"
	var second: Dictionary = repository.save_world(round_trip.world)
	check.call(second.errors.is_empty() and second.revision == 2 and second.slot == "b.json", "Next save revision 2 in slot B")
	check.call(repository.load_world().world.manager.name == "Revisão dois", "Highest valid revision selected")
	var third: Dictionary = repository.save_world(round_trip.world)
	check.call(third.errors.is_empty() and third.revision == 3 and third.slot == "a.json", "Save revision 3 rotates back to A")
	_write(root_path.path_join("snapshot.tmp"), "orphan incomplete temp")
	check.call(repository.load_world().revision == 3, "Orphan temp is not treated as committed snapshot")
	_write(root_path.path_join("a.json"), "{truncated")
	var fallback: Dictionary = repository.load_world()
	check.call(fallback.errors.is_empty() and fallback.revision == 2 and fallback.slot == "b.json" and fallback.recovered, "Corrupt newest A falls back to B with recovery diagnostic")
	_write(root_path.path_join("a.json"), JSON.stringify(future))
	check.call(not repository.save_world(round_trip.world).errors.is_empty(), "Future schema snapshot protected even with valid fallback")
	_write(root_path.path_join("a.json"), "{truncated")
	for stage in ["after_temp", "before_promote", "after_target_removal"]:
		repository.failure_stage = stage
		var failed: Dictionary = repository.save_world(round_trip.world)
		check.call(not failed.errors.is_empty() and repository.load_world().revision == 2, "Injected failure preserves last valid snapshot: " + stage)
		check.call(not FileAccess.file_exists(root_path.path_join("snapshot.tmp")), "Aborted temporary file cleaned: " + stage)
	repository.failure_stage = ""
	check.call(repository.save_world(round_trip.world).revision == 3, "Save recovers after failed attempts without revision skip")
	var old_name: String = round_trip.world.manager.name
	round_trip.world.manager.name = "Nome Ção UTF-8"
	check.call(repository.save_world(round_trip.world).errors.is_empty() and repository.load_world().world.manager.name == "Nome Ção UTF-8", "UTF-8 survives real file round-trip")
	round_trip.world.manager.name = old_name
	_write(root_path.path_join("a.json"), "corrupt A")
	_write(root_path.path_join("b.json"), "corrupt B")
	check.call(repository.load_world().world == null, "Both snapshots corrupt -> explicit error, no new career")
	check.call(not repository.save_world(round_trip.world).errors.is_empty(), "Both corrupt snapshots not silently overwritten by save")
	check.call(not Repository.new("res://invalid").save_world(round_trip.world).errors.is_empty(), "Repository refuses res:// storage")
	for name in ["a.json", "b.json", "snapshot.tmp"]:
		var path: String = root_path.path_join(name)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(root_path)
	check.call(not DirAccess.dir_exists_absolute(root_path), "Test files and exclusive test directory cleaned")

## Test-only file corruption seam; never targets normal player save directory.
func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
