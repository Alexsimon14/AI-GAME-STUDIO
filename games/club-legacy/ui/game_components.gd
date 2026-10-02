extends RefCounted
const T = preload("res://ui/slice_theme.gd")
const Badge = preload("res://ui/club_badge.gd")
const Identity = preload("res://ui/club_identity.gd")

static func label(parent: Node, text: String, font_size: int = T.BODY, color: Color = T.TEXT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if font_size >= T.SECTION: node.add_theme_font_override("font", T.display_font())
	parent.add_child(node)
	return node

static func card(parent: Node, title: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var body := VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(body)
	if not title.is_empty(): label(body, title, T.CARD, T.GOLD)
	return body

static func button(parent: Node, text: String, action: Callable, node_name: String = "", primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 44
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not node_name.is_empty(): node.name = node_name
	if primary:
		for state in ["normal", "hover", "pressed"]:
			node.add_theme_stylebox_override(state, T.box(T.GOLD.lightened(0.08) if state == "hover" else T.GOLD, T.MD, T.BUTTON_RADIUS))
		for state in ["font_color", "font_hover_color", "font_pressed_color"]: node.add_theme_color_override(state, T.BACKGROUND)
	if action.is_valid(): node.pressed.connect(action)
	parent.add_child(node)
	return node

static func selected(node: Button, value: bool) -> void:
	node.add_theme_stylebox_override("normal", T.box(T.ELEVATED if value else T.PANEL, T.MD, T.BUTTON_RADIUS))
	if value:
		var style := T.box(T.ELEVATED, T.MD, T.BUTTON_RADIUS)
		style.border_color = T.GOLD
		node.add_theme_stylebox_override("normal", style)
	node.add_theme_color_override("font_color", T.GOLD if value else T.MUTED)
	
static func club(parent: Node, model, dimension: int = 42, show_name: bool = true) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(row)
	var badge = Badge.new(Identity.get_identity(model), dimension)
	badge.name = "ClubBadge"
	row.add_child(badge)
	if show_name: label(row, model.name, T.CARD)
	return row

static func condition(parent: Node, value: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.value = value
	bar.custom_minimum_size = Vector2(74, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_theme_stylebox_override("fill", T.box(T.SUCCESS if value >= 70 else (T.WARNING if value >= 40 else T.DANGER), 0, T.BADGE_RADIUS))
	parent.add_child(bar)
	return bar

static func player(parent: Node, model, action: Callable = Callable(), status: String = "") -> Control:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var row := HBoxContainer.new()
	panel.add_child(row)
	# A numbered shirt silhouette is the portrait placeholder, never a real photograph.
	var shirt := Label.new()
	shirt.text = model.position + "\n" + str(model.overall)
	shirt.add_theme_font_override("font", T.display_font())
	shirt.add_theme_color_override("font_color", T.GOLD)
	shirt.add_theme_font_size_override("font_size", T.SECTION)
	shirt.custom_minimum_size.x = 46
	row.add_child(shirt)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)
	label(info, model.name, T.BODY)
	label(info, "POT %d · %s" % [model.potential, status], T.CAPTION, T.MUTED)
	condition(info, model.condition)
	if action.is_valid(): button(row, "Trocar", action)
	return panel

static func empty(parent: Node, message: String) -> Label:
	var node := label(parent, message, T.BODY, T.MUTED)
	node.name = "EmptyState"
	return node
