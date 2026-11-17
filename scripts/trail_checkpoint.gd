@tool
class_name TrailCheckpoint
extends Area2D

signal reached(point: Vector2)
var _active := false

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Hiker:
		reached.emit($Spawn.global_position)

func set_checkpoint_state(active: bool) -> void:
	_active = active
	queue_redraw()

func _draw() -> void:
	var light := Color("#ffd78f") if _active else Color("#a3c1ae")
	var ring := Color(1.0, 0.68, 0.33, 0.18) if _active else Color(0.6, 0.78, 0.7, 0.12)
	draw_circle(Vector2(0, -54), 32, ring, true, -1.0, true)
	draw_line(Vector2(0, -2), Vector2(0, -71), Color("#6a8070"), 6.0, true)
	draw_line(Vector2(2, -2), Vector2(2, -71), Color("#a4a989"), 1.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -71), Vector2(35, -68), Vector2(27, -54), Vector2(35, -42), Vector2(0, -46)]), Color("#36584f"))
	draw_polyline(PackedVector2Array([Vector2(0, -71), Vector2(35, -68), Vector2(27, -54), Vector2(35, -42), Vector2(0, -46)]), light, 2.0, true)
	draw_line(Vector2(11, -56), Vector2(22, -56), light, 3.0, true)
	draw_circle(Vector2(0, -73), 4.0, light, true, -1.0, true)
