extends RefCounted
const Factory = preload("res://scripts/domain/services/world_factory.gd")
const WorldConfig = preload("res://resources/config/world_config.tres")
const FinanceConfig = preload("res://resources/config/finance_config.gd")
const Finance = preload("res://scripts/domain/finance/finance_service.gd")
const Season = preload("res://scripts/domain/services/season_service.gd")
const Codec = preload("res://scripts/persistence/world_codec.gd")
const Envelope = preload("res://scripts/persistence/save_envelope.gd")
const Repository = preload("res://scripts/persistence/save_repository.gd")
const Flow = preload("res://scripts/application/career_flow.gd")
const MainScene = preload("res://scenes/main.tscn")
const Money = preload("res://ui/money_formatter.gd")
const Checkpoint = preload("res://scripts/persistence/match_checkpoint_codec.gd")

func _world(world_namespace: String = "finance-test"):
	var world = Factory.new().create(WorldConfig, 62026, "Finance Owner", "MEDIO", world_namespace).world
	Season.new().create(world)
	return world

func _commit(world, round_number: int) -> void:
	var competition = Season.new()
	for fixture in world.fixtures.values():
		if fixture.round == round_number and fixture.status != "COMPLETED":
			competition.submit_result(world, fixture.id, 1, 1, "finance-fixture:" + fixture.id)
	competition.commit_round(world, round_number, "finance-commit:" + str(round_number))

func run(check: Callable) -> void:
	var finance = Finance.new()
	var config = FinanceConfig.new()
	var world = _world()
	var openings: Dictionary = {}
	for club in world.clubs.values(): openings[club.id] = club.cash
	check.call(finance.initialize(world, config).errors.is_empty(), "6 initialize all twelve club finances")
	check.call(world.finance.entries.size() == 12, "6 one opening balance per club")
	check.call(world.finance.processed_rounds.is_empty(), "6 initialization does not charge a round")
	check.call(world.validation_errors().is_empty(), "6 initialized aggregate validates")
	check.call(_round_trip_equal(world), "6 initialized financial world round-trips before first game")
	var entry_ids: Dictionary = {}
	var keys: Dictionary = {}
	for entry in world.finance.entries.values():
		entry_ids[entry.id] = true
		keys[entry.operation_key] = true
	check.call(entry_ids.size() == 12 and keys.size() == 12, "6 financial IDs and opening keys unique")
	for club in world.clubs.values():
		check.call(finance.balance(world, club.id) == openings[club.id] and club.cash == openings[club.id], "6 opening balance reconciles " + club.id)
	var frozen: Dictionary = Codec.new().encode(world).payload
	check.call(not finance.process_round(world, 1).errors.is_empty(), "6 incomplete sporting round cannot incur finance")
	check.call(not finance.process_round(world, 2).errors.is_empty(), "6 future round rejected")
	check.call(Codec.new().encode(world).payload == frozen, "6 rejected processing leaves aggregate unchanged")
	_commit(world, 1)
	check.call(finance.process_round(world, 1).errors.is_empty(), "6 committed round processes all clubs")
	check.call(world.finance.entries.size() == 42, "6 round has six gate receipts and twelve pairs of costs")
	check.call(_round_trip_equal(world), "6 first-round financial state round-trips exactly")
	for club in world.clubs.values():
		var entries: Array = finance.ledger(world, club.id)
		var wages: int = 0
		var maintenance: int = 0
		var gate: int = 0
		var gate_count: int = 0
		var is_home: bool = false
		for fixture in world.fixtures.values():
			if fixture.round == 1 and fixture.home_club_id == club.id: is_home = true
		for entry in entries:
			match entry.category:
				"WAGES": wages += entry.amount
				"MAINTENANCE": maintenance += entry.amount
				"MATCHDAY_REVENUE":
					gate += entry.amount
					gate_count += 1
					check.call(entry.context.attendance >= 0 and entry.context.attendance <= entry.context.capacity and entry.amount == entry.context.attendance * entry.context.ticket_price, "6 attendance bounded and income uses integer ticket price " + club.id)
		check.call(wages == -world.payroll(club.id), "6 wages equal active contract payroll " + club.id)
		check.call(maintenance == -config.maintenance_per_round[club.profile], "6 configured mandatory maintenance " + club.id)
		check.call(gate_count == (1 if is_home else 0), "6 gate income only to actual fixture home club " + club.id)
		check.call(club.cash == openings[club.id] + gate + wages + maintenance, "6 balance reconciles movements " + club.id)
		var summary: Dictionary = finance.summary(world, club.id)
		check.call(summary.balance == club.cash and summary.net == summary.income - summary.expenses and summary.payroll == world.payroll(club.id), "6 summary reconciles real ledger " + club.id)
	frozen = Codec.new().encode(world).payload
	check.call(finance.process_round(world, 1).errors.is_empty(), "6 repeated round succeeds idempotently")
	check.call(Codec.new().encode(world).payload == frozen, "6 repeated round creates no IDs or money")
	var existing = world.finance.entries.values()[0]
	check.call(finance.apply_operation(world, existing.descriptor()).errors.is_empty(), "6 identical operation retry accepted")
	var conflicting: Dictionary = existing.descriptor()
	conflicting.amount += 1
	check.call(not finance.apply_operation(world, conflicting).errors.is_empty(), "6 same key different content rejected")
	check.call(Codec.new().encode(world).payload == frozen, "6 operation retry/conflict preserves full state")
	for club in world.clubs.values():
		finance.balance(world, club.id)
		finance.summary(world, club.id)
		var detached: Array = finance.ledger(world, club.id)
		detached[0].amount = -999
	check.call(Codec.new().encode(world).payload == frozen, "6 queries and modified projections do not mutate ledger/RNG")
	for movement in world.finance.entries.values():
		if movement.category == "MAINTENANCE":
			var maintenance_value: Variant = movement.context.maintenance_per_round
			movement.context.maintenance_per_round = float(maintenance_value)
			check.call(not world.validation_errors().is_empty(), "6 fractional-type maintenance context rejected even when numerically equal")
			movement.context.maintenance_per_round = maintenance_value
			break
	var first_club = world.clubs.values()[0]
	var original_cash: int = first_club.cash
	first_club.cash += 1
	check.call(not world.validation_errors().is_empty(), "6 materialized cash divergence rejected")
	first_club.cash = original_cash
	var original_category: String = existing.category
	existing.category = "FREE_MONEY"
	check.call(not world.validation_errors().is_empty(), "6 unknown category rejected")
	existing.category = original_category
	var original_club: String = existing.club_id
	existing.club_id = "missing"
	check.call(not world.validation_errors().is_empty(), "6 orphan ledger club rejected")
	existing.club_id = original_club
	var original_key: String = existing.operation_key
	existing.operation_key = ""
	check.call(not world.validation_errors().is_empty(), "6 empty financial operation key rejected")
	existing.operation_key = original_key
	var original_id: String = existing.id
	existing.id = world.manager.id
	check.call(not world.validation_errors().is_empty(), "6 financial ID collision with manager rejected")
	existing.id = original_id
	var original_profile: String = first_club.profile
	first_club.profile = "UNKNOWN"
	check.call(not world.validation_errors().is_empty(), "6 unknown financial profile rejected without dictionary crash")
	first_club.profile = original_profile
	var original_finance = world.finance
	world.finance = RefCounted.new()
	check.call(not world.validation_errors().is_empty(), "6 wrong financial model rejected safely")
	world.finance = original_finance
	for round_number in range(2, 11):
		_commit(world, round_number)
		check.call(finance.process_round(world, round_number).errors.is_empty(), "6 process next committed round " + str(round_number))
		if round_number == 2: check.call(_round_trip_equal(world), "6 second-round financial state round-trips exactly")
	check.call(world.finance.entries.size() == 312 and world.finance.processed_rounds.size() == 10, "6 ten rounds accounted exactly once without season prize")
	check.call(world.validation_errors().is_empty(), "6 complete financial season validates")
	_negative_and_config(check, finance)
	_persistence(check, world, finance)
	_migration_and_corruption(check)
	_ui(check, finance)

func _negative_and_config(check: Callable, finance) -> void:
	var config = FinanceConfig.new()
	config.ticket_price = 0
	config.maintenance_per_round = {"PEQUENO": 200000, "MEDIO": 200000, "ELITE": 200000}
	var world = _world("finance-negative")
	check.call(finance.initialize(world, config).errors.is_empty(), "6 dedicated negative-cash TEST configuration accepted")
	var frozen_config: Dictionary = world.finance.config_snapshot.duplicate(true)
	config.ticket_price = 999
	check.call(world.finance.config_snapshot == frozen_config, "6 effective financial configuration frozen independently")
	_commit(world, 1)
	check.call(finance.process_round(world, 1).errors.is_empty(), "6 mandatory expenses may cause negative cash")
	check.call(world.clubs.values().all(func(club): return club.cash < 0), "6 all profiles can enter deficit without bailout")
	check.call(world.validation_errors().is_empty(), "6 valid deficits are not rejected as corruption")
	_commit(world, 2)
	check.call(finance.process_round(world, 2).errors.is_empty(), "6 deficit does not block second round or obligations")
	var encoded: Dictionary = Envelope.new().pack(world, 1)
	var loaded: Dictionary = Envelope.new().unpack(encoded.text)
	check.call(loaded.errors.is_empty() and Codec.new().encode(loaded.world).payload == Codec.new().encode(world).payload, "6 negative balances and keys survive real JSON")
	var invalid = FinanceConfig.new()
	invalid.occupancy_basis_points.MEDIO = 10001
	check.call(not finance.initialize(_world("finance-invalid"), invalid).errors.is_empty(), "6 occupancy outside capacity bounds rejected")
	invalid = FinanceConfig.new()
	invalid.maintenance_per_round.MEDIO = 1.5
	check.call(not finance.initialize(_world("finance-fraction"), invalid).errors.is_empty(), "6 fractional monetary configuration rejected")
	var baseline_world = _world("finance-bad-baseline")
	var before: Dictionary = Codec.new().encode(baseline_world).payload
	check.call(not finance.initialize(baseline_world, FinanceConfig.new(), 11).errors.is_empty() and Codec.new().encode(baseline_world).payload == before, "6 failed initialization baseline eleven leaves IDs and cash unchanged")

func _persistence(check: Callable, world, finance) -> void:
	var path: String = "user://phase6_tests_" + str(Time.get_ticks_usec())
	var repository = Repository.new(path)
	check.call(repository.save_world(world).errors.is_empty(), "6 ledger saved to dedicated A/B repository")
	var loaded: Dictionary = repository.load_world()
	check.call(loaded.errors.is_empty() and Codec.new().encode(loaded.world).payload == Codec.new().encode(world).payload, "6 all IDs/config/keys/rounds round-trip on disk")
	var before: Dictionary = Codec.new().encode(loaded.world).payload
	var packed: Dictionary = JSON.parse_string(Envelope.new().pack(loaded.world, 1).text)
	packed.payload.clubs[0].cash = "999999"
	packed.checksum = Envelope.new().checksum(packed)
	check.call(Envelope.new().unpack(JSON.stringify(packed)).world == null, "6 rechecksummed cash/ledger divergence rejected on load")
	check.call(finance.process_round(loaded.world, 10).errors.is_empty() and Codec.new().encode(loaded.world).payload == before, "6 loaded round retry cannot duplicate cash")
	check.call(repository.save_world(loaded.world).revision == 2, "6 financial snapshots alternate to revision two")
	var file = FileAccess.open(path + "/b.json", FileAccess.WRITE)
	file.store_string("corrupted financial snapshot")
	file.close()
	var fallback: Dictionary = repository.load_world()
	check.call(fallback.errors.is_empty() and fallback.recovered and fallback.revision == 1, "6 corrupt newest financial snapshot falls back to previous valid ledger")
	var legacy = _world("finance-migration")
	_commit(legacy, 1)
	var envelope = Envelope.new()
	var data: Dictionary = JSON.parse_string(envelope.pack(legacy, 7).text)
	data.schema_version = 3
	data.save_version = "phase-4-v1"
	data.payload.erase("finance")
	data.checksum = envelope.checksum(data)
	var migrated: Dictionary = envelope.unpack(JSON.stringify(data))
	check.call(migrated.errors.is_empty(), "6 real schema three migrates committed competition")
	if migrated.world != null:
		check.call(migrated.world.finance.baseline_committed_round == 1 and migrated.world.finance.entries.size() == 12, "6 migration initializes openings without retroactive round charges")
		check.call(migrated.world.fixtures.keys() == legacy.fixtures.keys() and migrated.world.manager.id == legacy.manager.id, "6 migration preserves existing fixture and manager IDs")
		check.call(finance.process_round(migrated.world, 1).errors.is_empty() and migrated.world.finance.entries.size() == 12, "6 migration baseline prevents historical billing")
		_commit(migrated.world, 2)
		check.call(finance.process_round(migrated.world, 2).errors.is_empty() and migrated.world.finance.entries.size() == 42, "6 migrated career bills only future newly committed round")
	for filename in ["a.json", "b.json", "snapshot.tmp"]:
		if FileAccess.file_exists(path + "/" + filename): DirAccess.remove_absolute(path + "/" + filename)
	DirAccess.remove_absolute(path)
	check.call(not DirAccess.dir_exists_absolute(path), "6 isolated financial save files cleaned")

func _round_trip_equal(world) -> bool:
	var envelope = Envelope.new()
	var loaded: Dictionary = envelope.unpack(envelope.pack(world, 1).text)
	return loaded.world != null and Codec.new().encode(loaded.world).payload == Codec.new().encode(world).payload

func _legacy_text(world, revision: int = 7) -> String:
	var envelope = Envelope.new()
	var data: Dictionary = JSON.parse_string(envelope.pack(world, revision).text)
	data.schema_version = 3
	data.save_version = "phase-4-v1"
	data.payload.erase("finance")
	data.checksum = envelope.checksum(data)
	return JSON.stringify(data)

func _migration_and_corruption(check: Callable) -> void:
	var envelope = Envelope.new()
	var partial = _world("finance-partial-migration")
	var fixture = partial.fixtures.values()[0]
	Season.new().submit_result(partial, fixture.id, 2, 0, "partial-result")
	var partial_loaded: Dictionary = envelope.unpack(_legacy_text(partial))
	check.call(partial_loaded.world != null and partial_loaded.world.finance.baseline_committed_round == 0, "6 partial legacy round has zero financial baseline")
	if partial_loaded.world != null:
		check.call(partial_loaded.world.fixtures[fixture.id].home_goals == 2 and partial_loaded.world.finance.entries.size() == 12, "6 partial result preserved without early charges")
	var flow = Flow.new("user://phase6_unused_active_fixture")
	flow.create_career("Checkpoint", "MEDIO", 622, "finance-active-migration")
	flow.start_match()
	flow.set_paused(false)
	for _minute in range(23): flow.advance_match()
	flow.set_paused(true)
	flow.world.active_match = Checkpoint.new().encode(flow.match_state)
	var checkpoint: Dictionary = flow.world.active_match.duplicate(true)
	var text: String = _legacy_text(flow.world)
	var active: Dictionary = envelope.unpack(text)
	check.call(active.world != null and JSON.stringify(active.world.active_match, "", true) == JSON.stringify(JSON.parse_string(JSON.stringify(checkpoint)), "", true), "6 active legacy checkpoint including RNG/input/events preserved exactly")
	var path: String = "user://phase6_legacy_tests_" + str(Time.get_ticks_usec())
	DirAccess.make_dir_recursive_absolute(path)
	var file = FileAccess.open(path + "/a.json", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	var repository = Repository.new(path)
	var loaded: Dictionary = repository.load_world()
	check.call(loaded.world != null and FileAccess.get_file_as_string(path + "/a.json") == text, "6 migration load leaves legacy file unchanged")
	if loaded.world != null:
		var saved: Dictionary = repository.save_world(loaded.world)
		check.call(saved.errors.is_empty() and saved.revision == 8 and saved.slot == "b.json" and FileAccess.get_file_as_string(path + "/a.json") == text, "6 migrated save uses next revision/inactive slot preserving old snapshot")
	var initialized = _world("finance-corrupt-codec")
	Finance.new().initialize(initialized)
	var data: Dictionary = JSON.parse_string(envelope.pack(initialized, 1).text)
	for variant in ["checksum", "future", "amount_type", "duplicate_key", "future_round", "enormous_baseline", "float_opening_context"]:
		var bad: Dictionary = data.duplicate(true)
		match variant:
			"checksum": bad.payload.finance.entries[0].amount = "999"
			"future": bad.schema_version = 999
			"amount_type": bad.payload.finance.entries[0].amount = 1.5
			"duplicate_key": bad.payload.finance.entries[1].operation_key = bad.payload.finance.entries[0].operation_key
			"future_round": bad.payload.finance.entries[0].round_number = "99"
			"enormous_baseline": bad.payload.finance.baseline_committed_round = "9223372036854775807"
			"float_opening_context": bad.payload.finance.entries[0].context.baseline_committed_round = 1.5
		if variant != "checksum": bad.checksum = envelope.checksum(bad)
		check.call(envelope.unpack(JSON.stringify(bad)).world == null, "6 corrupted finance envelope rejected: " + variant)
	for filename in ["a.json", "b.json", "snapshot.tmp"]:
		if FileAccess.file_exists(path + "/" + filename): DirAccess.remove_absolute(path + "/" + filename)
	DirAccess.remove_absolute(path)
	check.call(not DirAccess.dir_exists_absolute(path), "6 legacy migration repository cleaned")

func _ui(check: Callable, finance) -> void:
	var tree = Engine.get_main_loop()
	var session = tree.root.get_node("GameSession")
	var previous = session.flow
	var path: String = "user://phase6_ui_tests_" + str(Time.get_ticks_usec())
	session.flow = Flow.new(path)
	var main = MainScene.instantiate()
	tree.root.add_child(main)
	check.call(session.act("create_career", ["Economia", "MEDIO", 62026, "finance-ui"]), "6 UI creates career with initialized ledger")
	var flow = session.flow
	var before: Dictionary = Codec.new().encode(flow.world).payload
	check.call(session.act("navigate", ["FINANCES"]), "6 functional sidebar destination Finances enabled")
	check.call(not main._shell.nav.FINANCES.disabled, "6 Finances navigation item enabled after career creation")
	check.call(main.find_child("FinanceBalance", true, false) != null and main.find_child("FinanceLedger", true, false) != null, "6 real balance and ledger UI present")
	var summary: Dictionary = finance.summary(flow.world, flow.club_id())
	for field in {"FinanceBalance": "balance", "FinanceIncome": "income", "FinanceExpenses": "expenses", "FinanceNet": "net", "FinancePayroll": "payroll"}:
		var attribute: String = {"FinanceBalance": "balance", "FinanceIncome": "income", "FinanceExpenses": "expenses", "FinanceNet": "net", "FinancePayroll": "payroll"}[field]
		check.call(main.find_child(field, true, false).text == Money.format_amount(summary[attribute]), "6 displayed metric matches domain " + field)
	var ledger = main.find_child("FinanceLedger", true, false)
	var displayed: int = 0
	for child in ledger.get_children():
		if child.has_meta("financial_entry"):
			var entry: Dictionary = child.get_meta("financial_entry")
			check.call(flow.world.finance.entries.has(entry.id) and entry == flow.world.finance.entries[entry.id].projection(), "6 displayed financial movement is canonical ledger row")
			displayed += 1
	check.call(displayed == 1, "6 initial finance screen shows genuine opening only")
	check.call(Codec.new().encode(flow.world).payload == before, "6 opening Finances screen cannot mutate world or RNG")
	session.act("navigate", ["HOME"])
	session.act("navigate", ["FINANCES"])
	check.call(Codec.new().encode(flow.world).payload == before, "6 Home/Finances navigation leaves ledger/calendar/RNG intact")
	var deficit = _world("finance-ui-deficit")
	var negative_config = FinanceConfig.new()
	negative_config.ticket_price = 0
	negative_config.maintenance_per_round = {"PEQUENO": 200000, "MEDIO": 200000, "ELITE": 200000}
	finance.initialize(deficit, negative_config)
	_commit(deficit, 1)
	finance.process_round(deficit, 1)
	flow.world = deficit
	session.act("navigate", ["HOME"])
	session.act("navigate", ["FINANCES"])
	var negative_balance = main.find_child("FinanceBalance", true, false)
	check.call(negative_balance.text == Money.format_amount(deficit.clubs[flow.club_id()].cash) and negative_balance.text.contains("-"), "6 negative ledger balance displayed explicitly without fabricated debt")
	check.call(Money.format_amount(-20000).contains("-") and Money.format_amount(20000) != Money.format_amount(-20000), "6 negative fictional cash has explicit sign")
	main.free()
	session.flow = previous
	check.call(not DirAccess.dir_exists_absolute(path), "6 UI read-only test creates no disk save")
