extends RefCounted
## Native Controls, projections and actions only. No competition or football calculations.
const Colors = preload("res://ui/slice_theme.gd")
var main: Control
var flow: RefCounted
var _body: VBoxContainer

func build(controller: Control, parent: Control) -> void:
	main = controller
	flow = main.session.flow
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "top", "right", "bottom"]: margin.add_theme_constant_override("margin_" + side, 24)
	parent.add_child(margin)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_body)
	var header := HBoxContainer.new()
	_body.add_child(header)
	_label(header, "CLUB LEGACY", 28, Colors.GOLD)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	_label(header, "PRIMEIRA EXPERIÊNCIA", 13, Colors.MUTED)
	if flow.screen != "START":
		var nav := HFlowContainer.new()
		_body.add_child(nav)
		for item in [["HOME", "Carreira"], ["SQUAD", "Elenco"], ["LINEUP", "Escalação"], ["TABLE", "Classificação"], ["START", "Início"]]:
			_button(nav, item[1], func(): main.action("navigate", [item[0]]))
		_button(nav, "Salvar", func(): main.action("save"))
		if flow.match_state != null: _button(nav, "Retomar partida", func(): main.action("navigate", ["MATCH"]))
	if not flow.notice.is_empty(): main.notice_label = _label(_body, flow.notice, 15, Colors.GOLD)
	match flow.screen:
		"START": _start()
		"HOME": _home()
		"SQUAD": _squad()
		"LINEUP": _lineup()
		"MATCH": _match()
		"RESULT": _result()
		"TABLE": _table()

func _start() -> void:
	_label(_body, "Sua carreira começa no banco de reservas.", 30)
	_label(_body, "Escolha seu primeiro clube. O treinador continua sendo você quando o clube mudar.", 17, Colors.MUTED)
	_label(_body, "Versão inicial: escalação, partidas e classificação. Gestão financeira e demissões ainda não estão disponíveis.", 15, Colors.MUTED)
	if flow.can_continue(): _button(_body, "CONTINUAR CARREIRA", func(): main.action("load_career"), "ContinueCareer")
	var card: VBoxContainer = _card(_body)
	_label(card, "Nova carreira", 23)
	_label(card, "Nome do treinador")
	var name_input := LineEdit.new()
	name_input.name = "ManagerName"
	name_input.placeholder_text = "Como você quer ser chamado?"
	name_input.max_length = 60
	card.add_child(name_input)
	var profile := OptionButton.new()
	profile.name = "ClubProfile"
	for text in ["PEQUENO", "MÉDIO", "ELITE"]: profile.add_item(text)
	card.add_child(profile)
	var description: Label = _label(card, "", 16, Colors.MUTED)
	var descriptions := ["Pouca estrutura e elenco limitado. Espaço para construir sua trajetória.", "Estrutura intermediária e elenco razoável.", "Elenco e estrutura superiores. Maior pressão será uma regra futura; não há demissão nesta versão."]
	description.text = descriptions[0]
	profile.item_selected.connect(func(index): description.text = descriptions[index])
	_button(card, "INICIAR CARREIRA", func(): main.request_new_career(name_input.text, ["PEQUENO", "MEDIO", "ELITE"][profile.selected]), "StartCareer")
	if not flow.can_continue(): _label(card, "Se houver um save com problema, ele será preservado. Você pode tentar carregá-lo abaixo.", 14, Colors.MUTED)
	_button(card, "Tentar carregar save", func(): main.action("load_career"))

func _home() -> void:
	var world = flow.world
	var club = world.clubs[flow.club_id()]
	_label(_body, club.name, 32)
	_label(_body, "Treinador: " + world.manager.name + "  ·  " + _profile(club.profile) + "  ·  " + world.leagues[club.league_id].name, 18, Colors.MUTED)
	var card: VBoxContainer = _card(_body)
	var position: int = 1
	for row in flow.standings(club.league_id):
		if row.club_id == club.id: break
		position += 1
	_label(card, "Rodada %d  ·  %dº na divisão" % [world.season.current_round, position], 24)
	var fixture_id: String = flow.next_fixture_id()
	if flow.match_state != null:
		_label(card, "Você tem uma partida em andamento.")
		_button(card, "RETOMAR PARTIDA", func(): main.action("navigate", ["MATCH"]))
	elif not fixture_id.is_empty():
		var f = world.fixtures[fixture_id]
		_label(card, "Próximo jogo: " + world.clubs[f.home_club_id].name + " × " + world.clubs[f.away_club_id].name, 22)
		_button(card, "ESCALAR E JOGAR", func(): main.action("navigate", ["LINEUP"]))
	else:
		_label(card, "Competição encerrada. A próxima temporada será incluída em uma etapa posterior.", 18)
	_label(_body, "Estádio: " + club.stadium_name + "  ·  Capacidade inicial: " + str(club.capacity), 16, Colors.MUTED)
	_label(_body, "Esta versão não processa receitas, despesas, pressão ou contratos ao avançar rodadas.", 15, Colors.MUTED)

func _squad() -> void:
	_label(_body, "Elenco", 30)
	_label(_body, "Confira seus atletas e prepare a próxima escalação.", 16, Colors.MUTED)
	var tree := Tree.new()
	tree.name = "SquadTable"
	tree.columns = 6
	tree.hide_root = true
	tree.column_titles_visible = true
	tree.custom_minimum_size.y = 500
	for col in range(6): tree.set_column_title(col, ["Atleta", "Posição", "Overall", "Potencial", "Condição", "Escalação"][col])
	var root = tree.create_item()
	for id in flow.world.roster_ids(flow.club_id()):
		var p = flow.world.players[id]
		var row = tree.create_item(root)
		var status: String = "Titular" if id in flow.lineup.get("starters", []) else ("Banco" if id in flow.lineup.get("bench", []) else "Não escalado")
		for col in range(6): row.set_text(col, [p.name, p.position, str(p.overall), str(p.potential), str(p.condition), status][col])
	_body.add_child(tree)
	_button(_body, "PREPARAR ESCALAÇÃO", func(): main.action("navigate", ["LINEUP"]))

func _lineup() -> void:
	_label(_body, "Escalação", 30)
	if flow.match_state != null:
		_label(_body, "As mudanças desta partida devem ser feitas na tela de jogo.")
		return
	var bar := HFlowContainer.new()
	_body.add_child(bar)
	var formation: OptionButton = _options(bar, ["4-4-2", "4-3-3", "5-3-2"], flow.formation)
	var tactic: OptionButton = _options(bar, ["CAUTELOSA", "EQUILIBRADA", "OFENSIVA"], flow.tactic)
	_label(_body, "Cautelosa: protege mais, cria menos. Equilibrada: distribuição neutra. Ofensiva: mais apoio à frente e maior exposição.", 15, Colors.MUTED)
	_button(bar, "Sugerir titulares", func(): main.action("suggest_lineup", [formation.get_item_text(formation.selected), tactic.get_item_text(tactic.selected)]))
	_label(_body, "Escolha Titular, Banco ou Não escalado para cada atleta. Confirme sua escalação antes de jogar.", 16)
	var picks: Dictionary = {}
	var rows_start: int = _body.get_child_count()
	for id in flow.world.roster_ids(flow.club_id()):
		var p = flow.world.players[id]
		var row := HBoxContainer.new()
		_body.add_child(row)
		var label: Label = _label(row, p.name + "  ·  " + p.position + "  ·  Overall " + str(p.overall) + "  ·  Condição " + str(p.condition))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var current: String = "Titular" if id in flow.lineup.get("starters", []) else ("Banco" if id in flow.lineup.get("bench", []) else "Não escalado")
		picks[id] = _options(row, ["Titular", "Banco", "Não escalado"], current)
	var confirm: Callable = func(play: bool):
		var starters: Array = []
		var bench: Array = []
		for id in picks:
			if picks[id].selected == 0: starters.append(id)
			elif picks[id].selected == 1: bench.append(id)
		if main.action("set_lineup", [starters, bench, formation.get_item_text(formation.selected), tactic.get_item_text(tactic.selected)]):
			if play: main.action("start_match")
			else: main.show_message("Escalação confirmada.")
	var confirm_button: Button = _button(_body, "CONFIRMAR ESCALAÇÃO", func(): confirm.call(false))
	var play_button: Button = _button(_body, "INICIAR PARTIDA", func(): confirm.call(true), "PlayMatch")
	_body.move_child(confirm_button, rows_start)
	_body.move_child(play_button, rows_start + 1)

func _match() -> void:
	var state = flow.match_state
	var score: Label = _label(_body, "", 30, Colors.GOLD)
	var clock: Label = _label(_body, "", 21)
	var stats: Label = _label(_body, "", 17, Colors.MUTED)
	main.match_labels = {"score": score, "clock": clock, "stats": stats}
	var bar := HFlowContainer.new()
	_body.add_child(bar)
	var pause: Button = _button(bar, "", func():
		flow.set_paused(not flow.paused)
		main.update_match(), "PauseMatch")
	main.match_labels["pause"] = pause
	for value in [1, 2, 4]: _button(bar, str(value) + "x", func(): main.action("set_speed", [value]))
	_button(bar, "Salvar partida", func(): main.action("save"))
	_label(_body, "Pause para escolher mudanças. Ao aplicar uma alteração, a partida fica pausada até você continuar.", 15, Colors.MUTED)
	var side: String = "home" if state.teams.home.club_id == flow.club_id() else "away"
	var team: Dictionary = state.teams[side]
	var commands: VBoxContainer = _card(_body)
	var tactical_row := HFlowContainer.new()
	commands.add_child(tactical_row)
	var tactic: OptionButton = _options(tactical_row, ["CAUTELOSA", "EQUILIBRADA", "OFENSIVA"], team.tactic)
	_pause_on_open(tactic)
	_button(tactical_row, "Aplicar tática", func(): main.action("match_command", ["TACTIC", {"tactic": tactic.get_item_text(tactic.selected)}]))
	var formation: OptionButton = _options(tactical_row, ["4-4-2", "4-3-3", "5-3-2"], team.formation)
	_pause_on_open(formation)
	_button(tactical_row, "Mudar formação", func(): main.action("match_command", ["FORMATION", {"formation": formation.get_item_text(formation.selected), "starters": team.starters.duplicate()}]))
	var sub_row := HFlowContainer.new()
	commands.add_child(sub_row)
	_label(sub_row, "Sai")
	var out_player: OptionButton = _player_options(sub_row, team.starters, team)
	_pause_on_open(out_player)
	_label(sub_row, "Entra")
	var in_player: OptionButton = _player_options(sub_row, team.bench, team)
	_pause_on_open(in_player)
	main.match_labels["out_players"] = out_player
	main.match_labels["in_players"] = in_player
	var substitute: Button = _button(sub_row, "SUBSTITUIR", func():
		if out_player.selected >= 0 and in_player.selected >= 0: main.action("match_command", ["SUBSTITUTE", {"out": out_player.get_item_metadata(out_player.selected), "in": in_player.get_item_metadata(in_player.selected)}]))
	substitute.disabled = team.substitutions >= 3 or team.bench.is_empty()
	_label(commands, "Substituições: %d / 3" % team.substitutions, 15, Colors.MUTED)
	var events := RichTextLabel.new()
	events.name = "MatchEvents"
	events.custom_minimum_size.y = 240
	events.scroll_following = true
	_body.add_child(events)
	main.match_labels["events"] = events
	if state.phase == "FINISHED": _button(_body, "Confirmar resultado e rodada", func(): main.action("finish_round"))
	main.update_match()

func _result() -> void:
	var result: Dictionary = flow.last_result.snapshot()
	_label(_body, "Resultado da partida", 30)
	_label(_body, _score(result.home_club_id, result.away_club_id, result.stats), 30, Colors.GOLD)
	_label(_body, _stats(result.stats, 90), 18)
	_label(_body, "A rodada foi concluída. A classificação já está atualizada.", 16, Colors.MUTED)
	for event in result.events:
		if event.kind == "GOAL": _label(_body, event_text(event), 17)
	_button(_body, "CONTINUAR", func(): main.action("navigate", ["HOME"]), "ContinueResult")
	_button(_body, "VER CLASSIFICAÇÃO", func(): main.action("navigate", ["TABLE"]))

func _table() -> void:
	_label(_body, "Classificação", 30)
	_label(_body, "A tabela inclui somente resultados confirmados. Finanças ainda não são processadas.", 15, Colors.MUTED)
	var leagues: Array = flow.world.leagues.keys()
	leagues.sort()
	for league_id in leagues:
		_label(_body, flow.world.leagues[league_id].name, 22, Colors.GOLD)
		var tree := Tree.new()
		tree.columns = 11
		tree.hide_root = true
		tree.column_titles_visible = true
		tree.custom_minimum_size.y = 240
		for col in range(11):
			tree.set_column_title(col, ["Pos", "Clube", "J", "V", "E", "D", "GP", "GC", "SG", "PTS", ""][col])
			tree.set_column_expand(col, col == 1)
			tree.set_column_custom_minimum_width(col, 180 if col == 1 else 46)
		var root = tree.create_item()
		var position: int = 1
		for row in flow.standings(league_id):
			var item = tree.create_item(root)
			var values: Array = [position, flow.world.clubs[row.club_id].name, row.played, row.wins, row.draws, row.losses, row.goals_for, row.goals_against, row.goal_difference, row.points, "←" if row.club_id == flow.club_id() else ""]
			for col in range(11): item.set_text(col, str(values[col]))
			position += 1
		_body.add_child(tree)

func event_text(event: Dictionary) -> String:
	var kinds := {"START": "Início da partida", "CHANCE": "Oportunidade", "CHANCE_LOST": "Chance não concluída", "SHOT_OFF_TARGET": "Finalização para fora", "SAVE": "Defesa do goleiro", "GOAL": "GOL", "HALF_TIME": "INTERVALO", "END": "Fim da partida", "TACTIC": "Tática alterada", "FORMATION": "Formação alterada", "SUBSTITUTE": "Substituição"}
	var text: String = "%d'  %s" % [event.minute, kinds.get(event.kind, event.kind)]
	if not event.club_id.is_empty(): text += " · " + flow.world.clubs[event.club_id].name
	if not event.player_id.is_empty() and flow.world.players.has(event.player_id): text += " · " + flow.world.players[event.player_id].name
	return text

func _score(home: String, away: String, stats: Dictionary) -> String:
	return "%s  %d × %d  %s" % [flow.world.clubs[home].name, stats.home.goals, stats.away.goals, flow.world.clubs[away].name]

func _stats(stats: Dictionary, minute: int) -> String:
	return "Chances %d — %d   ·   Finalizações %d — %d   ·   No alvo %d — %d\nPosse aproximada: %.0f%% — %.0f%%" % [stats.home.chances, stats.away.chances, stats.home.shots, stats.away.shots, stats.home.on_target, stats.away.on_target, stats.home.possession_percent, stats.away.possession_percent]

func _pause_on_open(option: OptionButton) -> void:
	option.get_popup().about_to_popup.connect(func():
		flow.set_paused(true)
		main.update_match())

func _card(parent: Node) -> VBoxContainer:
	var panel := PanelContainer.new()
	parent.add_child(panel)
	var box := VBoxContainer.new()
	panel.add_child(box)
	return box

func _label(parent: Node, text: String, font_size: int = 17, color: Color = Colors.TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer or parent is HFlowContainer else TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable, node_name: String = "") -> Button:
	var button := Button.new()
	button.text = text
	if not node_name.is_empty(): button.name = node_name
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _options(parent: Node, values: Array, current: String) -> OptionButton:
	var option := OptionButton.new()
	for value in values: option.add_item(value)
	option.select(maxi(0, values.find(current)))
	parent.add_child(option)
	return option

func _player_options(parent: Node, ids: Array, team: Dictionary) -> OptionButton:
	var option := OptionButton.new()
	for id in ids:
		var p = flow.world.players[id]
		option.add_item("%s · %s · %.0f%%" % [p.name, p.position, team.players[id].condition])
		option.set_item_metadata(option.item_count - 1, id)
	parent.add_child(option)
	return option

func _profile(value: String) -> String:
	return "MÉDIO" if value == "MEDIO" else value
