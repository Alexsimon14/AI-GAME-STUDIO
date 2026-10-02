extends RefCounted
const C = preload("res://ui/game_components.gd")
const T = preload("res://ui/slice_theme.gd")
var body: VBoxContainer
var context: HBoxContainer
var nav: Dictionary = {}
var sidebar: PanelContainer
var scroll: ScrollContainer
var controller: Control

func build(main: Control, parent: Control) -> void:
	controller = main
	var shell := HBoxContainer.new()
	shell.name = "AppShell"
	shell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shell.add_theme_constant_override("separation", 0)
	parent.add_child(shell)
	sidebar = PanelContainer.new()
	sidebar.name = "Sidebar"
	sidebar.custom_minimum_size.x = 176
	sidebar.add_theme_stylebox_override("panel", T.box(T.BACKGROUND, T.MD, 0))
	shell.add_child(sidebar)
	var sidebar_body := VBoxContainer.new()
	sidebar_body.add_theme_constant_override("separation", T.SM)
	sidebar.add_child(sidebar_body)
	# Keep the brand outside the scrolling navigation, with room for font ascenders.
	var brand_margin := MarginContainer.new()
	brand_margin.add_theme_constant_override("margin_top", T.SM)
	brand_margin.add_theme_constant_override("margin_bottom", T.SM)
	sidebar_body.add_child(brand_margin)
	var brand := C.label(brand_margin, "CLUB\nLEGACY", T.TITLE, T.GOLD)
	brand.name = "SidebarBrand"
	brand.autowrap_mode = TextServer.AUTOWRAP_OFF
	var sidebar_scroll := ScrollContainer.new()
	sidebar_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar_body.add_child(sidebar_scroll)
	var aside := VBoxContainer.new()
	aside.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aside.add_theme_constant_override("separation", T.XS)
	sidebar_scroll.add_child(aside)
	C.label(aside, "SUA HISTÓRIA.\nSEU LEGADO.", T.CAPTION, T.MUTED)
	C.label(aside, "PRINCIPAL", T.CAPTION, T.MUTED)
	for item in [["HOME", "Início"], ["SQUAD", "Elenco"], ["LINEUP", "Escalação"], ["TABLE", "Competições"]]:
		var node: Button = C.button(aside, item[1], func(): main.action("navigate", [item[0]]))
		node.alignment = HORIZONTAL_ALIGNMENT_LEFT
		node.name = "Nav" + item[0]
		nav[item[0]] = node
	C.label(aside, "GERENCIAMENTO", T.CAPTION, T.MUTED)
	nav["FINANCES"] = C.button(aside, "Finanças", func(): main.action("navigate", ["FINANCES"]), "NavFINANCES")
	nav["FINANCES"].alignment = HORIZONTAL_ALIGNMENT_LEFT
	for text in ["Clube", "Mercado", "Estádio", "CT", "Empregos"]:
		var node: Button = C.button(aside, text + "  ·  em breve", Callable())
		node.disabled = true
		node.custom_minimum_size.y = 32
		node.add_theme_stylebox_override("disabled", T.box(T.PANEL.darkened(0.2), T.XS, T.BUTTON_RADIUS))
		node.add_theme_font_size_override("font_size", T.CAPTION)
		node.tooltip_text = "Sistema disponível em uma etapa futura."
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	aside.add_child(spacer)
	nav.save = C.button(sidebar_body, "Salvar carreira", func(): main.action("save"), "SaveCareer")
	nav.start = C.button(sidebar_body, "Nova / continuar", func(): main.action("navigate", ["START"]))
	var area := VBoxContainer.new()
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shell.add_child(area)
	var top := PanelContainer.new()
	top.name = "TopBar"
	top.add_theme_stylebox_override("panel", T.box(T.BACKGROUND, T.LG, 0))
	area.add_child(top)
	context = HBoxContainer.new()
	top.add_child(context)
	scroll = ScrollContainer.new()
	scroll.name = "ContentScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, T.LG)
	scroll.add_child(margin)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(body)
	main.resized.connect(func(): sidebar.custom_minimum_size.x = 144 if main.size.x < 950 else 176)

func refresh(flow) -> void:
	for child in context.get_children():
		context.remove_child(child)
		child.queue_free()
	if flow.world != null:
		var world = flow.world
		var club = world.clubs[flow.club_id()]
		C.club(context, club, 32)
		C.label(context, "TEMPORADA %d\n%s" % [world.season.number, world.leagues[club.league_id].name], T.CAPTION, T.MUTED)
		var manager: Label = C.label(context, world.manager.name + "\nTREINADOR", T.CAPTION)
		manager.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else: C.label(context, "CONSTRUA SUA CARREIRA", T.CAPTION, T.MUTED)
	for key in ["HOME", "SQUAD", "LINEUP", "TABLE", "FINANCES"]:
		nav[key].disabled = flow.world == null
		C.selected(nav[key], flow.screen == key)
	nav.save.disabled = flow.world == null
