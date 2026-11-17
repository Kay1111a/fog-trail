@tool
extends Node2D
## Scatters quiet scenery around the authored ground. It has no collision.

func _draw() -> void:
	var terrain := get_node_or_null("../Terrain")
	if terrain == null:
		return
	for child in terrain.get_children():
		if child is TrailPlatform and not child.bridge and child.size.x >= 110.0:
			_decorate(child.position, child.size.x)

func _decorate(origin: Vector2, width: float) -> void:
	for step in range(28, int(width) - 24, 47):
		var seed := int(origin.x + float(step) * 13.0) % 61
		var base: Vector2 = origin + Vector2(step, 0)
		var rise: float = 3 + float(seed % 11)
		var tint := Color("#769684") if seed % 3 == 0 else Color("#5f8174")
		for blade in range(-1, 2):
			draw_line(base + Vector2(blade * 3, 0), base + Vector2(blade * 6, -rise + abs(blade) * 3.0), tint, 1.8, true)
		if seed % 7 == 0:
			draw_circle(base + Vector2(0, -rise), 2.4, Color("#dbb77e"), true, -1.0, true)
		if seed % 7 == 1:
			_stone(base + Vector2(10, -1), 15.0 + (seed % 5))
		if seed % 16 == 0 and width > 290 and origin.y >= 465.0:
			_stone(base + Vector2(29, 0), 39.0)

func _stone(base: Vector2, width: float) -> void:
	var points := PackedVector2Array([
		base, base + Vector2(width * 0.13, -width * 0.28), base + Vector2(width * 0.51, -width * 0.41),
		base + Vector2(width * 0.87, -width * 0.23), base + Vector2(width, 0)
	])
	draw_colored_polygon(points, Color("#4b635f"))
	draw_polyline(points.slice(1, 4), Color("#7a9186"), 1.4, true)
