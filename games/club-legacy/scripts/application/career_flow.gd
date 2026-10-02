extends RefCounted
## Application orchestration, testable without Node/SceneTree. No football/economy rules.
const Factory = preload("res://scripts/domain/services/world_factory.gd")
const Config = preload("res://resources/config/world_config.tres")
const Season = preload("res://scripts/domain/services/season_service.gd")
const Table = preload("res://scripts/domain/services/table_calculator.gd")
const Adapter = preload("res://scripts/application/fixture_match_adapter.gd")
const Selector = preload("res://scripts/domain/services/lineup_selector.gd")
const Simulator = preload("res://scripts/domain/match/match_simulator.gd")
const MatchInputModel = preload("res://scripts/domain/match/match_input.gd")
const Checkpoint = preload("res://scripts/persistence/match_checkpoint_codec.gd")
const Codec = preload("res://scripts/persistence/world_codec.gd")
const Repository = preload("res://scripts/persistence/save_repository.gd")
var world: RefCounted = null
var match_state: RefCounted = null
var last_result: RefCounted = null
var screen: String = "START"
var lineup: Dictionary = {}
var formation: String = "4-4-2"
var tactic: String = "EQUILIBRADA"
var paused: bool = true
var speed: int = 1
var notice: String = ""
var last_errors := PackedStringArray()
var repository: RefCounted
var _simulator = Simulator.new()
var _adapter = Adapter.new()
var _budget: float = 0.0
var _replace_on_save: bool = false

func _init(directory: String = "user://club_legacy_save") -> void:
	repository = Repository.new(directory)

func create_career(manager_name: String, profile: String, seed_value: int = 1001, career_namespace: String = "", replace_existing: bool = false) -> bool:
	if needs_replacement_confirmation() and not replace_existing: return _fail("Confirme a substituição da carreira antes de começar outra.")
	# Explicitly authorized replacement uses a different dedicated save directory only after confirmation.
	# The single logical save must be replaced safely; repository owns this operation.
	if career_namespace.is_empty(): career_namespace = Crypto.new().generate_random_bytes(16).hex_encode()
	var created: Dictionary = Factory.new().create(Config, seed_value, manager_name.strip_edges(), profile, career_namespace)
	if not created.errors.is_empty(): return _fail("Informe um nome e um perfil válidos.")
	if not Season.new().create(created.world).errors.is_empty(): return _fail("Não foi possível preparar a temporada.")
	world = created.world
	_replace_on_save = replace_existing
	match_state = null
	last_result = null
	formation = "4-4-2"
	tactic = "EQUILIBRADA"
	lineup = Selector.new().select(world, club_id(), formation)
	paused = true
	_budget = 0
	screen = "HOME"
	notice = "Carreira iniciada. Salve para guardar seu progresso."
	last_errors.clear()
	return true

func club_id() -> String:
	if world == null: return ""
	return world.contracts[world.manager.employment_contract_id].club_id

func next_fixture_id() -> String:
	if world == null or world.season.status in ["COMPLETED", "AWAITING_COMPLETION"]: return ""
	var ids: Array = world.fixtures.keys()
	ids.sort()
	for id in ids:
		var f = world.fixtures[id]
		if f.round == world.season.current_round and club_id() in [f.home_club_id, f.away_club_id] and f.status != "COMPLETED": return id
	return ""

func navigate(target: String) -> bool:
	if target not in ["START", "HOME", "SQUAD", "LINEUP", "MATCH", "RESULT", "TABLE"]: return _fail("Esta tela não está disponível.")
	if target != "START" and world == null: return _fail("Crie ou carregue uma carreira primeiro.")
	if target == "MATCH" and match_state == null: return _fail("Não há partida para acompanhar.")
	if target == "RESULT" and last_result == null: return _fail("Não há resultado detalhado nesta sessão.")
	if match_state != null and target != "MATCH": paused = true
	screen = target
	last_errors.clear()
	return true

func suggest_lineup(new_formation: String, new_tactic: String) -> bool:
	if world == null or match_state != null or new_formation not in MatchInputModel.FORMATIONS or new_tactic not in MatchInputModel.TACTICS: return _fail("Não é possível preparar esta escalação agora.")
	formation = new_formation
	tactic = new_tactic
	lineup = Selector.new().select(world, club_id(), formation)
	last_errors.clear()
	return true

func set_lineup(starters: Array, bench: Array, new_formation: String, new_tactic: String) -> bool:
	if world == null or match_state != null or next_fixture_id().is_empty(): return _fail("Não é possível alterar a escalação agora.")
	var selected := {"club_id": club_id(), "starters": starters.duplicate(), "bench": bench.duplicate()}
	var built: Dictionary = _adapter.build(world, next_fixture_id(), fixture_seed(next_fixture_id()), new_formation, new_tactic, selected)
	if not built.errors.is_empty(): return _fail("Escalação inválida. Escolha 11 titulares, um goleiro e os setores da formação; até 7 reservas, sem repetir atletas e usando seu elenco.")
	lineup = selected
	formation = new_formation
	tactic = new_tactic
	last_errors.clear()
	return true

func start_match() -> bool:
	if match_state != null: return navigate("MATCH")
	var fixture_id: String = next_fixture_id()
	if fixture_id.is_empty(): return _fail("Não há outra partida neste recorte. A próxima temporada ainda não está disponível.")
	var built: Dictionary = _adapter.build(world, fixture_id, fixture_seed(fixture_id), formation, tactic, lineup)
	if not built.errors.is_empty(): return _fail("Revise a escalação antes de iniciar a partida.")
	var created: Dictionary = _simulator.start(built.input)
	if not created.errors.is_empty(): return _fail("Não foi possível iniciar a partida.")
	match_state = created.state
	world.active_match = Checkpoint.new().encode(match_state)
	last_result = null
	paused = false
	speed = 1
	_budget = 0
	screen = "MATCH"
	last_errors.clear()
	return true

func set_speed(value: int) -> bool:
	if value not in [1, 2, 4]: return _fail("Selecione 1x, 2x ou 4x.")
	speed = value
	last_errors.clear()
	return true

func set_paused(value: bool) -> void:
	paused = value
	_budget = 0

func tick(delta: float) -> bool:
	if paused or screen != "MATCH" or match_state == null: return false
	_budget += maxf(0, delta) * speed
	var changed: bool = false
	while _budget >= 0.75 and match_state != null and not paused:
		_budget -= 0.75
		if not advance_match():
			set_paused(true)
			return true # Publish the error once; retry is explicit, not an endless loop.
		changed = true
	return changed

func advance_match() -> bool:
	if match_state == null or paused: return false
	if match_state.phase == "FINISHED": return finish_round()
	if not _simulator.advance(match_state).errors.is_empty(): return _fail("A partida não pôde avançar.")
	if match_state.phase == "HALF_TIME":
		set_paused(true)
	elif match_state.phase == "FINISHED":
		return finish_round()
	return true

func match_command(kind: String, payload: Dictionary) -> bool:
	if match_state == null: return _fail("Não há partida ativa.")
	set_paused(true)
	var side: String = "home" if match_state.teams.home.club_id == club_id() else "away"
	var cmd := {"id": "slice-command:" + str(match_state.commands.size() + 1), "minute": match_state.minute, "side": side, "kind": kind, "payload": payload.duplicate(true)}
	var applied: Dictionary = _simulator.command(match_state, cmd)
	if not applied.errors.is_empty(): return _fail("Alteração inválida. Confira os atletas, a formação e o limite de 3 substituições.")
	last_errors.clear()
	return true

func finish_round() -> bool:
	if match_state == null:
		return last_result != null # Repeated presentation cannot resolve the round again.
	var result = _simulator.result(match_state)
	if result == null: return _fail("A partida ainda não terminou.")
	var candidate = _copy_world()
	if candidate == null: return _fail("Não foi possível validar a rodada; seu estado anterior foi preservado.")
	candidate.active_match = null
	var round_number: int = candidate.season.current_round
	var submitted: Dictionary = _adapter.submit(candidate, result, "slice-match:" + result.snapshot().fixture_id)
	if not submitted.errors.is_empty(): return _fail("Não foi possível confirmar o resultado.")
	var ids: Array = candidate.fixtures.keys()
	ids.sort()
	for id in ids:
		var f = candidate.fixtures[id]
		if f.round != round_number or f.status == "COMPLETED": continue
		var built: Dictionary = _adapter.build(candidate, id, fixture_seed(id), "4-4-2", "EQUILIBRADA")
		if not built.errors.is_empty(): return _fail("Não foi possível escalar um adversário; a rodada não foi confirmada.")
		var simulated: Dictionary = _simulator.simulate(built.input)
		if not simulated.errors.is_empty() or not _adapter.submit(candidate, simulated.result, "slice-match:" + id).errors.is_empty(): return _fail("Não foi possível concluir os outros jogos; tente novamente.")
	if not Season.new().commit_round(candidate, round_number, "slice-round:" + str(round_number)).errors.is_empty(): return _fail("A rodada não pôde ser confirmada.")
	if candidate.season.status == "AWAITING_COMPLETION":
		if not Season.new().finish(candidate, "slice-season:" + candidate.season.id).errors.is_empty(): return _fail("Não foi possível encerrar a competição.")
	if not candidate.validation_errors().is_empty(): return _fail("A rodada ficou inválida; seu estado anterior foi preservado.")
	world = candidate
	match_state = null
	last_result = result
	set_paused(true)
	screen = "RESULT"
	notice = "Rodada concluída. Salve para guardar o progresso."
	last_errors.clear()
	return true

func fixture_seed(id: String) -> int:
	# Derivation v1, stable SHA-256; independent of names, runtime hashes or presentation.
	return ("slice-fixture-seed-v1:" + str(world.career.seed) + ":" + id).sha256_text().substr(0, 15).hex_to_int()

func save() -> bool:
	if world == null: return _fail("Não há carreira para salvar.")
	var candidate = _copy_world()
	if candidate == null: return _fail("Não foi possível preparar o save. O arquivo anterior foi preservado.")
	candidate.active_match = Checkpoint.new().encode(match_state) if match_state != null else null
	var saved: Dictionary = repository.replace_world(candidate) if _replace_on_save else repository.save_world(candidate)
	if not saved.errors.is_empty(): return _fail("Não foi possível salvar. O save anterior foi preservado; confira espaço e permissões.")
	world = candidate
	_replace_on_save = false
	notice = "JOGO SALVO"
	last_errors.clear()
	return true

func can_continue() -> bool:
	return repository.load_world().errors.is_empty()

func needs_replacement_confirmation() -> bool:
	return world != null or repository.has_snapshots()

func load_career() -> bool:
	var loaded: Dictionary = repository.load_world()
	if not loaded.errors.is_empty(): return _fail("Não foi possível carregar uma carreira válida. Nenhum arquivo foi alterado.")
	var restored: RefCounted = null
	if loaded.world.active_match != null:
		var decoded: Dictionary = Checkpoint.new().decode(loaded.world.active_match)
		if not decoded.errors.is_empty(): return _fail("Não foi possível retomar a partida. O save foi preservado.")
		restored = decoded.state
	world = loaded.world
	_replace_on_save = false
	match_state = restored
	last_result = null
	formation = "4-4-2"
	tactic = "EQUILIBRADA"
	lineup = Selector.new().select(world, club_id(), formation)
	set_paused(true)
	speed = 1
	screen = "MATCH" if match_state != null else "HOME"
	notice = "O save mais recente apresentou problema. Uma versão anterior válida foi recuperada." if loaded.recovered else "Carreira carregada."
	last_errors.clear()
	return true

func standings(league_id: String) -> Array:
	return Table.new().calculate(world, league_id) if world != null else []

func match_view() -> Dictionary:
	if match_state == null: return {}
	var view: Dictionary = match_state.view()
	for side in ["home", "away"]:
		view.stats[side]["possession_percent"] = 0.0 if view.minute == 0 else 100.0 * view.stats[side].possession_ticks / view.minute
	return view

func _copy_world():
	var encoded: Dictionary = Codec.new().encode(world)
	if not encoded.errors.is_empty(): return null
	return Codec.new().decode(encoded.payload).world

func _fail(message: String) -> bool:
	last_errors = PackedStringArray([message])
	return false
