@tool
class_name TrailShelter
extends Area2D

signal approached

var _collected := 0
var _total := 3

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func set_progress(collected: int, total: int) -> void:
	_collected = collected
	_total = total
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if body is Hiker:
		approached.emit()

func _draw() -> void:
	var unlocked: bool = _collected == _total
	var light := Color("#f4c37b") if unlocked else Color("#7d856b")
	var amber := Color("#ffca77")
	for i in range(10, 0, -1):
		var radius: float = 33.0 + float(i) * 12.0
		draw_circle(Vector2(0, -72), radius, Color(1, 0.69, 0.38, 0.02 if unlocked else 0.009), true, -1.0, true)
	draw_rect(Rect2(-94, -87, 188, 84), Color("#52635d"))
	draw_rect(Rect2(-81, -82, 162, 79), Color("#3c4948"))
	for x in range(-78, 85, 12):
		draw_line(Vector2(x, -79), Vector2(x, -4), Color("#536560"), 1.0)
	draw_rect(Rect2(-30, -78, 60, 76), Color("#262f31"))
	draw_rect(Rect2(-24, -72, 48, 70), light)
	draw_rect(Rect2(-17, -65, 34, 62), Color("#f2d69b") if unlocked else Color("#3c4947"))
	if not unlocked:
		draw_line(Vector2(10, -37), Vector2(16, -37), amber, 3.0, true)
	draw_rect(Rect2(-68, -63, 24, 26), Color("#e0aa65"))
	draw_rect(Rect2(44, -63, 24, 26), Color("#e0aa65"))
	for x in [-68, 44]:
		draw_rect(Rect2(x, -63, 24, 26), Color("#242f34"), false, 4.0)
		draw_line(Vector2(x + 12, -62), Vector2(x + 12, -37), Color("#313a3b"), 2.0)
	draw_rect(Rect2(59, -132, 22, 65), Color("#454c4c"))
	draw_rect(Rect2(56, -135, 28, 7), Color("#6e7a72"))
	var roof := PackedVector2Array([Vector2(-112, -82), Vector2(0, -143), Vector2(113, -82), Vector2(105, -74), Vector2(0, -129), Vector2(-104, -74)])
	draw_colored_polygon(roof, Color("#25383c"))
	draw_polyline(roof.slice(0, 3), Color("#a1ab94"), 3.5, true)
	draw_line(Vector2(-104, -78), Vector2(105, -78), Color("#253637"), 3.0)
	draw_rect(Rect2(-107, -6, 214, 6), Color("#40554f"))
	for i in range(_total):
		var marker_x: float = (float(i) - float(_total - 1) * 0.5) * 13.0
		draw_circle(Vector2(marker_x, -96), 4.0, amber if i < _collected else Color("#677872"), true, -1.0, true)
