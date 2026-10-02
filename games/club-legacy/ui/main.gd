extends Control
const Views = preload("res://ui/slice_views.gd")
const Palette = preload("res://ui/slice_theme.gd")
const Shell = preload("res://ui/app_shell.gd")
const Components = preload("res://ui/game_components.gd")
var session: Node
var match_labels: Dictionary = {}
var notice_label: Label
var _views = Views.new()
var _shell = Shell.new()
var _built_screen: String = ""
var _built_commands: int = -1
var _built_match: RefCounted
var _dialog: AcceptDialog
var _confirm: ConfirmationDialog
var _pending_new: Array = []

func _ready() -> void:
	session = get_node("/root/GameSession")
	theme = Palette.make_theme()
	var background := ColorRect.new()
	background.color = Palette.BACKGROUND
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
	_dialog = AcceptDialog.new()
	_dialog.title = "Club Legacy"
	get_node("DialogLayer").add_child(_dialog)
	_confirm = ConfirmationDialog.new()
	_confirm.title = "Nova carreira"
	_confirm.dialog_text = "Substituir a carreira atual? O save anterior será substituído apenas quando você salvar a nova carreira."
	get_node("DialogLayer").add_child(_confirm)
	_confirm.confirmed.connect(func(): action("create_career", [_pending_new[0], _pending_new[1], 1001, "", true]))
	session.changed.connect(_on_changed)
	_shell.build(self, get_node("ScreenHost"))
	render()

func action(method: String, arguments: Array = []) -> bool:
	return session.act(method, arguments)

func request_new_career(manager_name: String, profile: String) -> void:
	if manager_name.strip_edges().is_empty():
		show_message("Informe o nome do treinador.")
		return
	if session.flow.needs_replacement_confirmation():
		_pending_new = [manager_name, profile]
		_confirm.popup_centered(Vector2i(480, 200))
	else:
		action("create_career", [manager_name, profile])

func _on_changed() -> void:
	if not session.flow.last_errors.is_empty():
		show_message(session.flow.last_errors[0])
		update_match()
		return
	var count: int = session.flow.match_state.commands.size() if session.flow.match_state != null else -1
	if session.flow.screen == "MATCH" and _built_screen == "MATCH" and count == _built_commands and _built_match == session.flow.match_state:
		update_match()
	else:
		render()

func render() -> void:
	var host = _shell.body
	for child in host.get_children():
		host.remove_child(child)
		child.queue_free()
	match_labels.clear()
	notice_label = null
	_built_screen = session.flow.screen
	_built_match = session.flow.match_state
	_built_commands = session.flow.match_state.commands.size() if session.flow.match_state != null else -1
	_shell.refresh(session.flow)
	_shell.scroll.scroll_vertical = 0
	_views.build(self, host)

func update_match() -> void:
	if match_labels.is_empty() or session.flow.match_state == null: return
	var view: Dictionary = session.flow.match_view()
	if notice_label != null: notice_label.text = session.flow.notice
	var team: Dictionary = view.teams.home if view.teams.home.club_id == session.flow.club_id() else view.teams.away
	for key in ["out_players", "in_players"]:
		if not match_labels.has(key): continue
		var options: OptionButton = match_labels[key]
		for index in range(options.item_count):
			var id: String = options.get_item_metadata(index)
			var player = session.flow.world.players[id]
			options.set_item_text(index, "%s · %s · %.0f%%" % [player.name, player.position, team.players[id].condition])
	match_labels.score.text = _views._score(view.teams.home.club_id, view.teams.away.club_id, view.stats)
	var phase: String = "INTERVALO" if view.phase == "HALF_TIME" else ("FIM DA PARTIDA" if view.phase == "FINISHED" else ("PAUSADO" if session.flow.paused else "EM JOGO"))
	match_labels.clock.text = "%d'  ·  %s  ·  %dx" % [view.minute, phase, session.flow.speed]
	_views.update_comparisons(match_labels.comparisons, view.stats)
	match_labels.possession.value = view.stats.home.possession_percent
	match_labels.pause.text = ("INICIAR SEGUNDO TEMPO" if view.phase == "HALF_TIME" else "CONTINUAR") if session.flow.paused else "PAUSAR"
	for value in match_labels.speeds: Components.selected(match_labels.speeds[value], value == session.flow.speed)
	match_labels.retry.visible = view.phase == "FINISHED"
	match_labels.pause.disabled = view.phase == "FINISHED"
	match_labels.events.text = ""
	for event in view.events.slice(maxi(0, view.events.size() - 18)):
		match_labels.events.append_text(_views.event_line(event))

func show_message(message: String) -> void:
	if session.flow.match_state != null:
		session.flow.set_paused(true)
		update_match()
	_dialog.dialog_text = message
	_dialog.popup_centered(Vector2i(500, 200))
