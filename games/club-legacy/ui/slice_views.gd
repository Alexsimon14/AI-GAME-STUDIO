extends RefCounted
## Screen composition only. Domain/application remain authoritative.
const C = preload("res://ui/game_components.gd")
const Colors = preload("res://ui/slice_theme.gd")
const Career = preload("res://ui/career_screens.gd")
const Lineup = preload("res://ui/lineup_screen.gd")
const Finances = preload("res://ui/finance_screen.gd")
var main: Control
var flow: RefCounted
var _body: VBoxContainer
var _career: RefCounted
var _lineup_view: RefCounted

func build(controller: Control, parent: VBoxContainer) -> void:
	main = controller
	flow = main.session.flow
	_body = parent
	_body.add_theme_constant_override("separation", Colors.MD)
	_career = Career.new()
	_career.setup(main, parent)
	if not flow.notice.is_empty(): main.notice_label = C.label(parent, flow.notice, Colors.CAPTION, Colors.GOLD)
	match flow.screen:
		"START": _career.start()
		"HOME": _career.home()
		"SQUAD": _career.squad()
		"LINEUP":
			_lineup_view = Lineup.new()
			_lineup_view.build(main, parent)
		"MATCH": _match()
		"RESULT": _result()
		"TABLE": _career.table()
		"FINANCES": Finances.new().build(main, parent)

func _duel(parent: Node, home: String, away: String) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	C.club(row, flow.world.clubs[home], 62)
	var score: Label = C.label(row, "", Colors.DISPLAY, Colors.GOLD)
	score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score.custom_minimum_size.x = 116
	C.club(row, flow.world.clubs[away], 62)
	return score

func _comparisons(parent: Node) -> Dictionary:
	var rows: Dictionary = {}
	for entry in [["possession_percent", "POSSE APROXIMADA"], ["chances", "CHANCES"], ["shots", "FINALIZAÇÕES"], ["on_target", "NO ALVO"]]:
		var row := HBoxContainer.new()
		parent.add_child(row)
		var home := C.label(row, "0", Colors.SECTION, Colors.GOLD)
		var title := C.label(row, entry[1], Colors.CAPTION, Colors.MUTED)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var away := C.label(row, "0", Colors.SECTION)
		away.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		rows[entry[0]] = [home, away]
	return rows

func update_comparisons(rows: Dictionary, stats: Dictionary) -> void:
	for key in rows:
		for i in range(2):
			var value = stats["home" if i == 0 else "away"][key]
			rows[key][i].text = ("%.0f%%" % value) if key == "possession_percent" else str(value)

func _match() -> void:
	var state = flow.match_state
	C.label(_body, "CENTRAL DA PARTIDA", Colors.TITLE)
	var head := C.card(_body)
	var score := _duel(head, state.teams.home.club_id, state.teams.away.club_id)
	var clock: Label = C.label(head, "", Colors.SECTION)
	clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main.match_labels = {"score": score, "clock": clock}
	var bar := HBoxContainer.new()
	head.add_child(bar)
	main.match_labels.pause = C.button(bar, "", func():
		flow.set_paused(not flow.paused)
		main.update_match(), "PauseMatch", true)
	main.match_labels.speeds = {}
	for value in [1, 2, 4]: main.match_labels.speeds[value] = C.button(bar, str(value) + "x", func(): main.action("set_speed", [value]))
	C.button(bar, "Salvar partida", func(): main.action("save"))
	var grid: GridContainer = _career.grid(_body)
	var timeline := C.card(grid, "LANCES DA PARTIDA")
	var events := RichTextLabel.new()
	events.name = "MatchEvents"
	events.bbcode_enabled = true
	events.custom_minimum_size.y = 240
	events.scroll_following = true
	timeline.add_child(events)
	main.match_labels.events = events
	var stats := C.card(grid, "ESTATÍSTICAS")
	main.match_labels.comparisons = _comparisons(stats)
	var possession := ProgressBar.new()
	possession.custom_minimum_size.y = 18
	possession.show_percentage = false
	stats.add_child(possession)
	main.match_labels.possession = possession
	C.label(stats, "Controle de iniciativa estimado pelo motor.", Colors.CAPTION, Colors.MUTED)
	var side: String = "home" if state.teams.home.club_id == flow.club_id() else "away"
	var team: Dictionary = state.teams[side]
	var commands := C.card(_body, "AJUSTES À BEIRA DO CAMPO")
	var tactics := HBoxContainer.new()
	commands.add_child(tactics)
	for value in ["CAUTELOSA", "EQUILIBRADA", "OFENSIVA"]:
		var node := C.button(tactics, value, func(): main.action("match_command", ["TACTIC", {"tactic": value}]))
		C.selected(node, value == team.tactic)
		main.match_labels["tactic_" + value] = node
	var formations := HBoxContainer.new()
	commands.add_child(formations)
	for value in ["4-4-2", "4-3-3", "5-3-2"]:
		var node := C.button(formations, value, func(): main.action("match_command", ["FORMATION", {"formation": value, "starters": team.starters.duplicate()}]))
		C.selected(node, value == team.formation)
	var sub_row := HBoxContainer.new()
	commands.add_child(sub_row)
	C.label(sub_row, "SAI", Colors.CAPTION, Colors.MUTED).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var out_player := _player_options(sub_row, team.starters, team)
	_pause_on_open(out_player)
	C.label(sub_row, "ENTRA", Colors.CAPTION, Colors.MUTED).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var in_player := _player_options(sub_row, team.bench, team)
	_pause_on_open(in_player)
	main.match_labels.out_players = out_player
	main.match_labels.in_players = in_player
	var substitute := C.button(commands, "CONFIRMAR SUBSTITUIÇÃO", func():
		if out_player.selected >= 0 and in_player.selected >= 0: main.action("match_command", ["SUBSTITUTE", {"out": out_player.get_item_metadata(out_player.selected), "in": in_player.get_item_metadata(in_player.selected)}]), "SubstitutePlayer")
	substitute.disabled = team.substitutions >= 3 or team.bench.is_empty()
	C.label(commands, "%d / 3 substituições · Ajustes pausam a partida até você continuar." % team.substitutions, Colors.CAPTION, Colors.MUTED)
	var retry := C.button(commands, "Confirmar resultado e rodada", func(): main.action("finish_round"), "RetryRound")
	retry.visible = state.phase == "FINISHED"
	main.match_labels.retry = retry
	main.update_match()

func _result() -> void:
	var result: Dictionary = flow.last_result.snapshot()
	C.label(_body, "APITO FINAL", Colors.TITLE)
	var head := C.card(_body)
	var score := _duel(head, result.home_club_id, result.away_club_id)
	score.text = _score(result.home_club_id, result.away_club_id, result.stats)
	var own: int = result.stats.home.goals if result.home_club_id == flow.club_id() else result.stats.away.goals
	var rival: int = result.stats.away.goals if result.home_club_id == flow.club_id() else result.stats.home.goals
	C.label(head, "VITÓRIA" if own > rival else ("EMPATE" if own == rival else "DERROTA"), Colors.SECTION, Colors.SUCCESS if own > rival else (Colors.MUTED if own == rival else Colors.DANGER)).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid: GridContainer = _career.grid(_body)
	var goals := C.card(grid, "GOLS")
	var has_goals: bool = false
	for event in result.events:
		if event.kind == "GOAL":
			C.label(goals, event_text(event), Colors.BODY, Colors.GOLD)
			has_goals = true
	if not has_goals: C.empty(goals, "O placar terminou sem gols.")
	var stats := C.card(grid, "ESTATÍSTICAS FINAIS")
	update_comparisons(_comparisons(stats), result.stats)
	C.label(_body, "Rodada concluída. A classificação está atualizada.", Colors.CAPTION, Colors.MUTED)
	C.button(_body, "CONTINUAR", func(): main.action("navigate", ["HOME"]), "ContinueResult", true)
	C.button(_body, "VER CLASSIFICAÇÃO", func(): main.action("navigate", ["TABLE"]))

func event_text(event: Dictionary) -> String:
	var kinds := {"START": "Início da partida", "CHANCE": "Oportunidade", "CHANCE_LOST": "Chance não concluída", "SHOT_OFF_TARGET": "Finalização para fora", "SAVE": "Defesa do goleiro", "GOAL": "GOL", "HALF_TIME": "INTERVALO", "END": "APITO FINAL", "TACTIC": "Tática alterada", "FORMATION": "Formação alterada", "SUBSTITUTE": "Substituição"}
	var text: String = "%d'  %s" % [event.minute, kinds.get(event.kind, event.kind)]
	if not event.club_id.is_empty(): text += " · " + flow.world.clubs[event.club_id].name
	if not event.player_id.is_empty() and flow.world.players.has(event.player_id): text += " · " + flow.world.players[event.player_id].name
	return text

func event_line(event: Dictionary) -> String:
	# Escape custom manager/player display text before adding BBCode emphasis.
	var text: String = event_text(event).replace("[", "[lb]")
	return "[color=#dfb76d][b]" + text + "[/b][/color]\n" if event.kind == "GOAL" else text + "\n"

func _score(_home: String, _away: String, stats: Dictionary) -> String:
	return "%d — %d" % [stats.home.goals, stats.away.goals]

func _pause_on_open(option: OptionButton) -> void:
	option.get_popup().about_to_popup.connect(func():
		flow.set_paused(true)
		main.update_match())

func _player_options(parent: Node, ids: Array, team: Dictionary) -> OptionButton:
	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.custom_minimum_size.y = 44
	for id in ids:
		var p = flow.world.players[id]
		option.add_item("%s · %s · %.0f%%" % [p.name, p.position, team.players[id].condition])
		option.set_item_metadata(option.item_count - 1, id)
	parent.add_child(option)
	return option
