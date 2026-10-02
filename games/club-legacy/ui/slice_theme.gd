extends RefCounted
const BACKGROUND = Color("101c2c")
const PANEL = Color("1b2b40")
const TEXT = Color("edf2f8")
const MUTED = Color("acbbcf")
const GOLD = Color("e8ba70")

static func make_theme() -> Theme:
	var theme := Theme.new()
	var body := SystemFont.new()
	body.font_names = PackedStringArray(["Segoe UI", "Noto Sans"])
	theme.default_font = body
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_color", "LineEdit", TEXT)
	for type in ["PanelContainer", "Button", "OptionButton", "LineEdit", "Tree"]:
		var box := StyleBoxFlat.new()
		box.bg_color = PANEL
		box.set_corner_radius_all(8)
		box.set_content_margin_all(12)
		box.border_color = Color("34485f")
		box.set_border_width_all(1)
		theme.set_stylebox("panel" if type in ["PanelContainer", "Tree"] else "normal", type, box)
		if type in ["Button", "OptionButton", "LineEdit"]:
			var focus = box.duplicate()
			focus.border_color = GOLD
			focus.set_border_width_all(2)
			theme.set_stylebox("focus", type, focus)
			if type != "LineEdit":
				var hover = box.duplicate()
				hover.bg_color = Color("2d425b")
				theme.set_stylebox("hover", type, hover)
	theme.set_constant("separation", "VBoxContainer", 14)
	theme.set_constant("separation", "HBoxContainer", 12)
	return theme
