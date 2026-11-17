class_name ForestBackdrop
extends Node2D
## A small parallax landscape drawn from original shapes and colors.

const VIEW := Vector2(1280, 720)
var travel := 0.0
var menu_view := true
var _drift := 0.0

func _process(delta: float) -> void:
	_drift = fposmod(_drift + delta * 0.32, TAU * 20.0)
	queue_redraw()

func _draw() -> void:
	_draw_sky()
	_ridge(363, 90, 0.05, 0.9, Color("#687d7c"))
	_ridge(429, 91, 0.12, 2.6, Color("#597573"))
	_pine_line(495, 0.19, 43, 102, Color("#4e6a67"), 4.1)
	_ridge(511, 60, 0.24, 1.6, Color("#456461"))
	_pine_line(565, 0.33, 52, 155, Color("#365754"), 9.1)
	_mist(483, 89, 0.05, 0.071)
	_ridge(602, 50, 0.38, 2.3, Color("#2f4c4c"))
	_pine_line(658, 0.53, 91, 228, Color("#274745"), 14.7)
	_mist(596, 110, 0.12, 0.062)
	if menu_view:
		_draw_menu_shelter()

func _draw_sky() -> void:
	var zenith := Color("#172c3b")
	var dusk := Color("#d9a582")
	var lower := Color("#8d9c8f")
	for step in range(72):
		var t: float = float(step) / 71.0
		var color: Color = zenith.lerp(dusk, smoothstep(0.0, 0.62, t))
		color = color.lerp(lower, smoothstep(0.52, 0.88, t))
		draw_rect(Rect2(0, step * 10, VIEW.x, 10), color)
	for i in range(64):
		var x: float = 30 + _noise(float(i) * 3.2 + 4.7) * 1220
		var y: float = 14 + _noise(float(i) * 9.1 + 5.1) * 166
		var scale: float = _noise(float(i) * 0.541 + 1.2)
		draw_circle(Vector2(x, y), 0.7 + scale * 1.15, Color(0.99, 0.91, 0.8, 0.12 + scale * 0.38), true, -1.0, true)
	var moon := Vector2(975 - fmod(travel * 0.018, 155.0), 202)
	for i in range(32, 0, -1):
		var spread: float = float(i) / 32.0
		draw_circle(moon, 55 + spread * 100, Color(1.0, 0.76, 0.54, 0.008 + (1.0 - spread) * 0.009), true, -1.0, true)
	draw_circle(moon, 54.0, Color("#fbe0ac"), true, -1.0, true)
	draw_arc(moon, 53.0, 0.0, TAU, 70, Color("#f7cc96"), 1.2, true)
	for i in range(6):
		var crater := Vector2(_noise(i * 2.1 + 19.0) - 0.5, _noise(i * 8.1 + 9.0) - 0.5) * 57.0
		draw_circle(moon + crater, 3.0 + 5.0 * _noise(i * 3.8 + 0.3), Color(0.88, 0.65, 0.51, 0.13), true, -1.0, true)
	for i in range(4):
		var y: float = 246.0 + float(i) * 31.0
		var x: float = 280.0 + _noise(32.0 + i * 5.0) * 710.0
		var line := PackedVector2Array([Vector2(x, y), Vector2(x + 100, y - 4), Vector2(x + 285, y - 7)])
		draw_polyline(line, Color(1.0, 0.86, 0.7, 0.14), 2.0, true)

func _ridge(level: float, amplitude: float, parallax: float, seed: float, color: Color) -> void:
	var points := PackedVector2Array()
	for x in range(-24, 1321, 32):
		var world_x: float = float(x) + travel * parallax
		var angle: float = world_x * 0.0043 + seed
		var ridge: float = sin(angle) * 0.66 + sin(angle * 1.78 + seed) * 0.26
		ridge += sin(angle * 4.9) * 0.09
		points.append(Vector2(x, level + ridge * amplitude))
	points.append(Vector2(1320, 748))
	points.append(Vector2(-32, 748))
	draw_colored_polygon(points, color)

func _pine_line(baseline: float, parallax: float, spacing: int, height_limit: float, color: Color, seed: float) -> void:
	var offset: float = travel * parallax
	var first: int = floori(offset / float(spacing)) - 2
	var last: int = ceili((offset + VIEW.x) / float(spacing)) + 1
	for index in range(first, last):
		var noise_index: float = float(index) + seed
		var center: float = float(index * spacing) + _noise(noise_index * 5.265) * float(spacing - 6) - offset
		var bottom: float = baseline + sin(float(index) * 0.62 + seed) * 28.0
		var height: float = 38.0 + _noise(noise_index * 2.381 + 4.2) * height_limit
		_pine(Vector2(center, bottom), height, color, _noise(noise_index * 3.01))

func _pine(base: Vector2, height: float, color: Color, tilt: float) -> void:
	var top: Vector2 = base - Vector2((tilt - 0.5) * height * 0.15, height)
	draw_line(top, base, color, maxf(2.0, height * 0.041))
	var shape := PackedVector2Array([top])
	for tier in range(1, 7):
		var part: float = float(tier) * 0.144
		var center: Vector2 = top.lerp(base, part)
		var size: float = height * (0.04 + part * 0.225)
		shape.append(center + Vector2(-size * 0.55, -height * 0.035))
		shape.append(center + Vector2(-size, height * 0.081))
		shape.append(center + Vector2(-size * 0.29, height * 0.053))
	for tier in range(6, 0, -1):
		var part: float = float(tier) * 0.144
		var center: Vector2 = top.lerp(base, part)
		var size: float = height * (0.04 + part * 0.23)
		shape.append(center + Vector2(size * 0.29, height * 0.071))
		shape.append(center + Vector2(size * 0.94, height * 0.10))
		shape.append(center + Vector2(size * 0.51, 0))
	draw_colored_polygon(shape, color)

func _mist(level: float, height: float, parallax: float, alpha: float) -> void:
	for strand in range(4):
		var points := PackedVector2Array()
		var middle: float = level + float(strand) * 16.0
		for x in range(-15, 1321, 34):
			var wave: float = sin(float(x) * 0.004 + travel * parallax * 0.004 + _drift * 0.16 + strand * 0.71)
			points.append(Vector2(x, middle + wave * 18.0))
		for x in range(1311, -32, -34):
			var wave: float = sin(float(x) * 0.003 - _drift * 0.23 + strand * 0.53)
			points.append(Vector2(x, middle + height + wave * 14.0))
		draw_colored_polygon(points, Color(0.72, 0.8, 0.74, alpha))

func _draw_menu_shelter() -> void:
	var hill := PackedVector2Array([
		Vector2(0, 724), Vector2(517, 704), Vector2(651, 666), Vector2(741, 641),
		Vector2(851, 611), Vector2(907, 585), Vector2(1054, 585), Vector2(1139, 602),
		Vector2(1280, 584), Vector2(1280, 724)
	])
	draw_colored_polygon(hill, Color("#1d353a"))
	draw_polyline(hill.slice(1, 9), Color("#557167"), 3.0, true)
	_pine(Vector2(1185, 603), 227.0, Color("#213c40"), 0.9)
	_pine(Vector2(1245, 594), 302.0, Color("#1d383c"), 0.7)
	var cabin := Vector2(985, 585)
	for i in range(15, 0, -1):
		draw_circle(cabin - Vector2(9, 62), 28.0 + float(i) * 8.0, Color(1.0, 0.60, 0.28, 0.013), true, -1.0, true)
	draw_rect(Rect2(cabin + Vector2(-77, -74), Vector2(155, 74)), Color("#3f4e4a"))
	for x in range(-73, 74, 11):
		draw_line(cabin + Vector2(x, -69), cabin + Vector2(x, -3), Color("#536056"), 1.0, true)
	draw_rect(Rect2(cabin + Vector2(53, -120), Vector2(17, 63)), Color("#34454a"))
	var roof := PackedVector2Array([
		cabin + Vector2(-94, -70), cabin + Vector2(0, -120), cabin + Vector2(95, -70),
		cabin + Vector2(90, -64), cabin + Vector2(-90, -64)
	])
	draw_colored_polygon(roof, Color("#23353b"))
	draw_polyline(roof.slice(0, 3), Color("#90a299"), 3.0, true)
	draw_rect(Rect2(cabin + Vector2(-14, -56), Vector2(30, 56)), Color("#222e32"))
	for x in [-58, 35]:
		draw_rect(Rect2(cabin + Vector2(x, -52), Vector2(22, 23)), Color("#ffc578"))
		draw_line(cabin + Vector2(x + 11, -52), cabin + Vector2(x + 11, -29), Color("#67533e"), 2.0)
	draw_rect(Rect2(cabin + Vector2(-83, -3), Vector2(167, 6)), Color("#172c33"))

func _noise(value: float) -> float:
	return fposmod(sin(value * 12.9898) * 43758.5453, 1.0)
