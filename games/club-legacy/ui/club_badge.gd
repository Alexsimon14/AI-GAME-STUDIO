extends Control
const Palette = preload("res://ui/slice_theme.gd")
var identity: Dictionary = {}
var _font: Font = Palette.display_font()
func _init(data: Dictionary = {}, dimension: int = 48) -> void:
	identity = data
	custom_minimum_size = Vector2(dimension, dimension + 6)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if identity.is_empty(): return
	var w: float = minf(size.x, size.y * 0.88)
	var h: float = w * 1.1
	var origin := Vector2((size.x - w) * 0.5, (size.y - h) * 0.5)
	var points := PackedVector2Array([origin + Vector2(2, 2), origin + Vector2(w - 2, 2), origin + Vector2(w - 3, h * 0.65), origin + Vector2(w * 0.5, h - 2), origin + Vector2(3, h * 0.65)])
	draw_colored_polygon(points, identity.primary)
	draw_polyline(points + PackedVector2Array([points[0]]), identity.secondary, 2, true)
	draw_line(origin + Vector2(w * 0.5, 5), origin + Vector2(w * 0.5, h * 0.79), Color(identity.secondary, 0.15), w * 0.17)
	var font: Font = _font
	var font_size: int = maxi(11, int(w * 0.25))
	var text: String = identity.abbreviation
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	draw_string(font, origin + Vector2((w - text_size.x) / 2, h * 0.52 + text_size.y * 0.15), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, identity.secondary)
