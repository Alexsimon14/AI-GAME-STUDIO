extends RefCounted
const C = preload("res://ui/game_components.gd")
const T = preload("res://ui/slice_theme.gd")
const Pitch = preload("res://ui/tactical_pitch.gd")
var main: Control
var flow: RefCounted
var body: VBoxContainer
var selection: Dictionary
var selected_id: String = ""
var current_formation: String
var current_tactic: String
var board: VBoxContainer
var hint: Label

func build(controller: Control, parent: VBoxContainer) -> void:
	main = controller
	flow = main.session.flow
	body = parent
	C.label(body, "PREPARAÇÃO DA PARTIDA", T.TITLE)
	if flow.match_state != null:
		C.empty(body, "A partida já está em andamento. Faça seus ajustes na central da partida.")
		C.button(body, "RETOMAR PARTIDA", func(): main.action("navigate", ["MATCH"]), "ResumeMatch", true)
		return
	selection = flow.lineup.duplicate(true)
	current_formation = flow.formation
	current_tactic = flow.tactic
	var formations := HBoxContainer.new()
	body.add_child(formations)
	for value in ["4-4-2", "4-3-3", "5-3-2"]:
		var node := C.button(formations, value, func(): main.action("suggest_lineup", [value, current_tactic]))
		C.selected(node, value == current_formation)
	var tactics := HBoxContainer.new()
	body.add_child(tactics)
	var buttons: Array = []
	for value in ["CAUTELOSA", "EQUILIBRADA", "OFENSIVA"]:
		var descriptions := {"CAUTELOSA": "Proteção e cautela", "EQUILIBRADA": "Distribuição neutra", "OFENSIVA": "Avançar e se expor"}
		var node := C.button(tactics, value + "\n" + descriptions[value], func():
			current_tactic = value
			for button in buttons: C.selected(button, button.get_meta("tactic") == value))
		node.set_meta("tactic", value)
		node.add_theme_font_size_override("font_size", T.CAPTION)
		buttons.append(node)
		C.selected(node, value == current_tactic)
	C.button(body, "Sugerir titulares", func(): main.action("suggest_lineup", [current_formation, current_tactic]))
	hint = C.label(body, "Toque em um titular no campo e escolha um atleta no banco para trocar.", T.CAPTION, T.MUTED)
	board = VBoxContainer.new()
	body.add_child(board)
	_draw_selection()
	var actions := HBoxContainer.new()
	body.add_child(actions)
	C.button(actions, "CONFIRMAR ESCALAÇÃO", func():
		if _confirm(): main.show_message("Escalação confirmada."), "ConfirmLineup")
	C.button(actions, "INICIAR PARTIDA", func():
		if _confirm(): main.action("start_match"), "PlayMatch", true)

func _confirm() -> bool:
	return main.action("set_lineup", [selection.starters, selection.bench, current_formation, current_tactic])

func _draw_selection() -> void:
	for child in board.get_children():
		board.remove_child(child)
		child.queue_free()
	var pitch := Pitch.new()
	board.add_child(pitch)
	pitch.setup(flow.world, selection.starters, current_formation, func(id):
		selected_id = id
		hint.text = "Selecionado: " + flow.world.players[id].name + ". Escolha a troca no banco abaixo.")
	var bench := C.card(board, "BANCO DE RESERVAS")
	bench.name = "BenchPanel"
	var rows := GridContainer.new()
	rows.columns = 2 if main.size.x >= 980 else 1
	bench.add_child(rows)
	var resize_action: Callable = func(): if is_instance_valid(rows): rows.columns = 2 if main.size.x >= 980 else 1
	main.resized.connect(resize_action)
	rows.tree_exiting.connect(func(): main.resized.disconnect(resize_action))
	for id in selection.bench:
		C.player(rows, flow.world.players[id], func(): swap(id), "BANCO")
	var unused: Array = []
	for id in flow.world.roster_ids(flow.club_id()):
		if id not in selection.starters and id not in selection.bench: unused.append(id)
	if not unused.is_empty():
		var available := C.card(board, "NÃO ESCALADOS")
		for id in unused: C.player(available, flow.world.players[id], func(): swap(id), "DISPONÍVEL")

func swap(id: String) -> void:
	if selected_id.is_empty():
		hint.text = "Selecione primeiro um titular no campo."
		return
	var starters: Array = selection.starters.duplicate()
	var bench: Array = selection.bench.duplicate()
	starters[starters.find(selected_id)] = id
	if id in bench: bench[bench.find(id)] = selected_id
	# Existing domain adapter validates positions, duplicates and counts before publishing.
	if main.action("set_lineup", [starters, bench, current_formation, current_tactic]):
		selected_id = ""
