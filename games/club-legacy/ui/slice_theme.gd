extends RefCounted
## Shared presentation tokens.
const BACKGROUND = Color("0b1018")
const PANEL = Color("141e2b")
const ELEVATED = Color("1d2a39")
const BORDER = Color("2d3b4c")
const TEXT = Color("edf0f4")
const MUTED = Color("a3b0bf")
const GOLD = Color("dfb76d")
const SUCCESS = Color("7bbd99")
const WARNING = Color("d5ae65")
const DANGER = Color("cd8483")
const XS = 4
const SM = 8
const MD = 12
const LG = 18
const XL = 24
const XXL = 32
const DISPLAY = 38
const TITLE = 27
const SECTION = 19
const CARD = 16
const BODY = 15
const CAPTION = 12
const NUMBER = 30
const CARD_RADIUS = 7
const BUTTON_RADIUS = 5
const INPUT_RADIUS = 5
const BADGE_RADIUS = 4
static func box(color: Color = PANEL, padding: int = LG, radius: int = CARD_RADIUS) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	style.border_color = BORDER
	style.set_border_width_all(1)
	return style
static func display_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Bahnschrift", "Segoe UI", "Noto Sans"])
	font.font_weight = 700
	return font
static func make_theme() -> Theme:
	var theme := Theme.new()
	var body := SystemFont.new()
	body.font_names = PackedStringArray(["Segoe UI", "Noto Sans"])
	theme.default_font = body
	theme.default_font_size = BODY
	for type in ["Label", "Button", "OptionButton", "LineEdit", "Tree", "RichTextLabel", "PopupMenu"]:
		theme.set_color("font_color", type, TEXT)
	theme.set_color("font_disabled_color", "Button", MUTED.darkened(0.25))
	theme.set_color("font_hover_color", "Button", GOLD)
	for type in ["PanelContainer", "Button", "OptionButton", "LineEdit", "Tree", "PopupMenu"]:
		var style := box(PANEL, MD, CARD_RADIUS if type == "PanelContainer" else BUTTON_RADIUS)
		theme.set_stylebox("panel" if type in ["PanelContainer", "Tree", "PopupMenu"] else "normal", type, style)
		if type in ["Button", "OptionButton", "LineEdit"]:
			var focus := box(Color.TRANSPARENT, MD, BUTTON_RADIUS)
			focus.border_color = GOLD
			focus.set_border_width_all(2)
			theme.set_stylebox("focus", type, focus)
			for state in ["hover", "pressed", "disabled"]:
				var variant := box(ELEVATED if state == "hover" else PANEL, MD, BUTTON_RADIUS)
				if state == "pressed": variant.border_color = GOLD
				if state == "disabled": variant.bg_color = PANEL.darkened(0.2)
				theme.set_stylebox(state, type, variant)
	theme.set_stylebox("selected", "Tree", box(ELEVATED, SM))
	theme.set_stylebox("selected_focus", "Tree", box(ELEVATED, SM))
	theme.set_constant("v_separation", "Tree", MD)
	theme.set_stylebox("background", "ProgressBar", box(BORDER, 0, BADGE_RADIUS))
	theme.set_stylebox("fill", "ProgressBar", box(SUCCESS, 0, BADGE_RADIUS))
	theme.set_constant("separation", "VBoxContainer", MD)
	theme.set_constant("separation", "HBoxContainer", MD)
	theme.set_constant("h_separation", "GridContainer", MD)
	theme.set_constant("v_separation", "GridContainer", MD)
	return theme
