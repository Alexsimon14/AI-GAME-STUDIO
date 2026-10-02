extends RefCounted
const C = preload("res://ui/game_components.gd")
const T = preload("res://ui/slice_theme.gd")
const Dashboard = preload("res://ui/dashboard_projection.gd")
var main: Control
var flow: RefCounted
var body: VBoxContainer

func setup(controller: Control, parent: VBoxContainer) -> void:
	main = controller
	flow = main.session.flow
	body = parent

func grid(parent: Node, columns: int = 2) -> GridContainer:
	var node := GridContainer.new()
	node.columns = columns if main.size.x >= 980 else 1
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(node)
	var resize_action: Callable = func(): if is_instance_valid(node): node.columns = columns if main.size.x >= 980 else 1
	main.resized.connect(resize_action)
	node.tree_exiting.connect(func(): main.resized.disconnect(resize_action))
	return node

func start() -> void:
	body.add_theme_constant_override("separation", T.SM)
	C.label(body, "SUA HISTÓRIA.\nSEU LEGADO.", T.NUMBER, T.GOLD)
	C.label(body, "Construa sua carreira. Transforme clubes. Deixe sua marca.", T.CARD, T.MUTED)
	# Peek through the existing validated repository. No save mutation or new persistence format.
	var loaded: Dictionary = flow.repository.load_world()
	if loaded.errors.is_empty():
		var saved = loaded.world
		var preview: VBoxContainer = C.card(body, "CONTINUAR CARREIRA")
		_compact_card(preview)
		var employment = saved.contracts[saved.manager.employment_contract_id]
		C.club(preview, saved.clubs[employment.club_id], 28)
		C.label(preview, saved.manager.name + " · Temporada " + str(saved.season.number), T.BODY, T.MUTED)
		if saved.active_match != null:
			var state: Dictionary = saved.active_match.resolved
			C.label(preview, "PARTIDA EM ANDAMENTO", T.CARD, T.GOLD)
			C.label(preview, "%s  %d — %d  %s · %d'" % [saved.clubs[state.teams.home.club_id].name, state.stats.home.goals, state.stats.away.goals, saved.clubs[state.teams.away.club_id].name, state.minute], T.CARD)
			C.button(preview, "RETOMAR PARTIDA", func(): main.action("load_career"), "ContinueCareer", true)
		else: C.button(preview, "CONTINUAR CARREIRA", func(): main.action("load_career"), "ContinueCareer", true)
	var card := C.card(body, "NOVA CARREIRA")
	_compact_card(card)
	C.label(card, "Nome do treinador", T.CAPTION, T.MUTED)
	var input := LineEdit.new()
	input.name = "ManagerName"
	input.placeholder_text = "Seu nome à beira do campo"
	input.max_length = 60
	input.custom_minimum_size.y = 44
	card.add_child(input)
	C.label(card, "ESCOLHA SEU DESAFIO", T.CARD, T.GOLD)
	var profiles := ["PEQUENO", "MEDIO", "ELITE"]
	var selected := {"index": 0}
	var buttons: Array = []
	var challenges := grid(card, 3)
	for i in range(3):
		var names := ["PEQUENO", "MÉDIO", "ELITE"]
		var descriptions := ["Poucos recursos.\nEspaço para crescer.", "Estrutura intermediária.\nEquilibre suas escolhas.", "Elenco forte.\nExpectativa de título."]
		var button := C.button(challenges, names[i] + "\n" + descriptions[i], func():
			selected.index = i
			for n in range(buttons.size()): C.selected(buttons[n], n == i))
		button.custom_minimum_size.y = 84
		buttons.append(button)
		C.selected(button, i == 0)
	C.button(card, "INICIAR CARREIRA", func(): main.request_new_career(input.text, profiles[selected.index]), "StartCareer", true)
	C.label(card, "Seu histórico pertence ao treinador, mesmo quando o clube muda.", T.CAPTION, T.MUTED)
	if not loaded.errors.is_empty() and flow.repository.has_snapshots():
		C.button(card, "Tentar recuperar carreira", func(): main.action("load_career"))

func _compact_card(card: VBoxContainer) -> void:
	card.add_theme_constant_override("separation", T.XS)
	card.get_parent().add_theme_stylebox_override("panel", T.box(T.PANEL, T.SM))

func home() -> void:
	var world = flow.world
	var club = world.clubs[flow.club_id()]
	var data: Dictionary = Dashboard.build(flow)
	C.label(body, "CENTRAL DO TREINADOR", T.TITLE)
	var next := C.card(body, "PRÓXIMO JOGO")
	next.name = "NextMatchCard"
	var fixture_id: String = flow.next_fixture_id()
	if not fixture_id.is_empty():
		var f = world.fixtures[fixture_id]
		C.label(next, "%s · Rodada %d · %s" % [world.leagues[f.league_id].name, f.round, "CASA" if f.home_club_id == club.id else "FORA"], T.CAPTION, T.MUTED)
		var duel := HBoxContainer.new()
		next.add_child(duel)
		C.club(duel, world.clubs[f.home_club_id], 66)
		var vs: Label = C.label(duel, "VS", T.NUMBER, T.GOLD)
		vs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vs.custom_minimum_size.x = 48
		C.club(duel, world.clubs[f.away_club_id], 66)
		C.label(next, "%dº na divisão" % data.position, T.BODY, T.MUTED)
		if flow.match_state != null: C.button(next, "RETOMAR PARTIDA", func(): main.action("navigate", ["MATCH"]), "PrepareMatch", true)
		else: C.button(next, "PREPARAR PARTIDA", func(): main.action("navigate", ["LINEUP"]), "PrepareMatch", true)
	else: C.empty(next, "Temporada encerrada. A próxima temporada faz parte de uma etapa futura.")
	var cards := grid(body)
	var table := C.card(cards, "CLASSIFICAÇÃO")
	table.name = "HomeStandings"
	standings(table, club.league_id, true)
	C.button(table, "VER CLASSIFICAÇÃO", func(): main.action("navigate", ["TABLE"]))
	var performance := C.card(cards, "DESEMPENHO")
	performance.name = "PerformanceCard"
	var stats := grid(performance, 3)
	for field in [["played", "JOGOS"], ["wins", "VITÓRIAS"], ["draws", "EMPATES"], ["losses", "DERROTAS"], ["goals_for", "GOLS PRÓ"], ["goals_against", "GOLS CONTRA"]]:
		var stat := VBoxContainer.new()
		stat.custom_minimum_size.x = 80
		stat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stats.add_child(stat)
		C.label(stat, str(data.performance.get(field[0], 0)), T.NUMBER)
		C.label(stat, field[1], T.CAPTION, T.MUTED)
	var recent := C.card(cards, "ÚLTIMOS RESULTADOS")
	recent.name = "RecentResults"
	if data.recent.is_empty(): C.empty(recent, "Você ainda não disputou partidas.")
	for f in data.recent:
		var won: bool = (f.home_goals > f.away_goals) == (f.home_club_id == club.id)
		var status: String = "E" if f.home_goals == f.away_goals else ("V" if won else "D")
		C.label(recent, "%s  ·  %s %d — %d %s" % [status, world.clubs[f.home_club_id].name, f.home_goals, f.away_goals, world.clubs[f.away_club_id].name], T.BODY, T.SUCCESS if status == "V" else (T.DANGER if status == "D" else T.MUTED))
	var upcoming := C.card(cards, "PRÓXIMAS PARTIDAS")
	upcoming.name = "UpcomingFixtures"
	if data.upcoming.is_empty(): C.empty(upcoming, "Calendário concluído.")
	for f in data.upcoming:
		var opponent: String = f.away_club_id if f.home_club_id == club.id else f.home_club_id
		var row := HBoxContainer.new()
		upcoming.add_child(row)
		var round_label := C.label(row, "R%d" % f.round, T.CAPTION, T.GOLD)
		round_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		round_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		round_label.custom_minimum_size.x = 28
		C.club(row, world.clubs[opponent], 24)
		var venue := C.label(row, "CASA" if f.home_club_id == club.id else "FORA", T.CAPTION, T.MUTED)
		venue.size_flags_horizontal = Control.SIZE_SHRINK_END
		venue.autowrap_mode = TextServer.AUTOWRAP_OFF
		venue.custom_minimum_size.x = 40
	var squad := C.card(body, "ELENCO EM DESTAQUE")
	C.label(squad, "%d JOGADORES · CONDIÇÃO MÉDIA %.0f%% · MELHOR OVR %d" % [data.roster_count, data.condition, data.best_overall], T.CAPTION, T.MUTED)
	var players := grid(squad)
	for id in data.highlights: C.player(players, world.players[id], Callable(), "Elenco atual")
	C.button(squad, "VER ELENCO", func(): main.action("navigate", ["SQUAD"]))

func squad() -> void:
	var data: Dictionary = Dashboard.build(flow)
	C.label(body, "ELENCO", T.TITLE)
	C.label(body, "%d JOGADORES · CONDIÇÃO MÉDIA %.0f%%" % [data.roster_count, data.condition], T.CARD, T.MUTED)
	var filter := HBoxContainer.new()
	body.add_child(filter)
	var table := Tree.new()
	table.name = "SquadTable"
	table.columns = 6
	table.hide_root = true
	table.column_titles_visible = true
	table.custom_minimum_size.y = 530
	for col in range(6):
		table.set_column_title(col, ["ATLETA", "POS", "OVR", "POT", "CONDIÇÃO", "STATUS"][col])
		table.set_column_expand(col, col == 0)
		table.set_column_custom_minimum_width(col, [190, 46, 46, 46, 90, 100][col])
	var populate := func(position: String):
		table.clear()
		var root = table.create_item()
		for id in flow.world.roster_ids(flow.club_id()):
			var p = flow.world.players[id]
			if position != "TODOS" and p.position != position: continue
			var item = table.create_item(root)
			var status: String = "TITULAR" if id in flow.lineup.get("starters", []) else ("BANCO" if id in flow.lineup.get("bench", []) else "DISPONÍVEL")
			for col in range(6):
				item.set_text(col, [p.name, p.position, str(p.overall), str(p.potential), str(p.condition) + "%", status][col])
				item.set_custom_color(col, T.GOLD if col == 2 else (T.SUCCESS if col == 4 else T.TEXT))
				if col > 0: item.set_text_alignment(col, HORIZONTAL_ALIGNMENT_CENTER)
	var filters: Array = []
	for position in ["TODOS", "GK", "DEF", "MID", "ATT"]:
		var node := C.button(filter, position, func():
			populate.call(position)
			for button in filters: C.selected(button, button.text == position))
		filters.append(node)
		C.selected(node, position == "TODOS")
	body.add_child(table)
	populate.call("TODOS")
	C.button(body, "PREPARAR ESCALAÇÃO", func(): main.action("navigate", ["LINEUP"]), "PrepareLineup", true)

func standings(parent: Node, league_id: String, compact: bool = false) -> void:
	var rows: Array = flow.standings(league_id)
	var club_id: String = flow.club_id()
	var grid_node := GridContainer.new()
	grid_node.columns = 4 if compact else 10
	grid_node.name = "StandingsTable"
	grid_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid_node)
	var titles: Array = ["POS", "CLUBE", "J", "PTS"] if compact else ["POS", "CLUBE", "J", "V", "E", "D", "GP", "GC", "SG", "PTS"]
	for title in titles:
		var heading := C.label(grid_node, title, T.CAPTION, T.MUTED)
		heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL if title == "CLUBE" else Control.SIZE_SHRINK_CENTER
		heading.autowrap_mode = TextServer.AUTOWRAP_OFF
		heading.custom_minimum_size.x = (140 if compact else 180) if title == "CLUBE" else 26
	for index in range(rows.size()):
		var row: Dictionary = rows[index]
		var color: Color = T.GOLD if row.club_id == club_id else T.TEXT
		var division: int = flow.world.leagues[league_id].tier
		var zone: Color = T.SUCCESS if division == 2 and index == 0 else (T.DANGER if division == 1 and index == rows.size() - 1 else color)
		C.label(grid_node, str(index + 1), T.BODY, zone).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var model = flow.world.clubs[row.club_id]
		var club_row := C.club(grid_node, model, 22)
		club_row.custom_minimum_size.x = 140 if compact else 180
		club_row.get_child(1).add_theme_color_override("font_color", color)
		club_row.get_child(1).add_theme_font_size_override("font_size", T.CAPTION if compact else T.BODY)
		var numbers: Array = [row.played, row.points] if compact else [row.played, row.wins, row.draws, row.losses, row.goals_for, row.goals_against, row.goal_difference, row.points]
		for value in numbers:
			var numeric := C.label(grid_node, str(value), T.BODY, color)
			numeric.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			numeric.autowrap_mode = TextServer.AUTOWRAP_OFF
			numeric.custom_minimum_size.x = 26
			numeric.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func table() -> void:
	C.label(body, "COMPETIÇÕES", T.TITLE)
	var leagues: Array = flow.world.leagues.keys()
	leagues.sort()
	for id in leagues:
		var card := C.card(body, flow.world.leagues[id].name.to_upper())
		standings(card, id)
		C.label(card, "1º lugar: acesso à primeira divisão" if flow.world.leagues[id].tier == 2 else "6º lugar: rebaixamento à segunda divisão", T.CAPTION, T.SUCCESS if flow.world.leagues[id].tier == 2 else T.DANGER)


