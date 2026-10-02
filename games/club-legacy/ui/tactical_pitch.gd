extends PanelContainer
## Static tactical board. Rows reflect the existing formation; no simulation or position rules.
const C = preload("res://ui/game_components.gd")
const T = preload("res://ui/slice_theme.gd")
var formation: String = ""
var slot_ids: Array = []
var line_counts: Array = []

func setup(world, starters: Array, formation_name: String, select: Callable) -> void:
	name = "TacticalPitch"
	formation = formation_name
	slot_ids = starters.duplicate()
	custom_minimum_size.y = 430
	add_theme_stylebox_override("panel", T.box(Color("142d32"), T.LG))
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", T.LG)
	add_child(rows)
	var groups := {"GK": [], "DEF": [], "MID": [], "ATT": []}
	for id in starters: groups[world.players[id].position].append(id)
	for position in ["ATT", "MID", "DEF", "GK"]:
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.add_child(line)
		line_counts.append(groups[position].size())
		for id in groups[position]:
			var p = world.players[id]
			var words: PackedStringArray = p.name.split(" ")
			var caption: String = words[0].left(1) + ". " + words[-1]
			var node: Button = C.button(line, "%s\n%s  %d · %d%%" % [caption, p.position, p.overall, p.condition], func(): select.call(id))
			node.custom_minimum_size = Vector2(0, 66)
			node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			node.custom_minimum_size.x = 90
			node.add_theme_font_size_override("font_size", T.CAPTION)
			node.set_meta("player_id", id)
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2(T.SM, T.SM), size - Vector2(T.SM * 2, T.SM * 2))
	var line := Color("78958f", 0.25)
	draw_rect(rect, line, false, 1)
	draw_line(Vector2(rect.position.x, size.y / 2), Vector2(rect.end.x, size.y / 2), line, 1)
	draw_arc(size / 2, size.x * 0.13, 0, TAU, 48, line, 1, true)
	for y in [rect.position.y, rect.end.y - size.y * 0.14]:
		draw_rect(Rect2(Vector2(size.x * 0.3, y), Vector2(size.x * 0.4, size.y * 0.14)), line, false, 1)
