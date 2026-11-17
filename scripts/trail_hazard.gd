@tool
class_name TrailHazard
extends Area2D

signal struck
@export var width: float = 96.0:
	set(value):
		width = maxf(value, 24.0)
		if is_node_ready():
			_refresh_shape()
			queue_redraw()

func _ready() -> void:
	_refresh_shape()
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _refresh_shape() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(width, 12)
	$CollisionShape2D.shape = rectangle
	$CollisionShape2D.position = Vector2(width * 0.5, -5)

func _on_body_entered(body: Node2D) -> void:
	if body is Hiker:
		struck.emit()

func _draw() -> void:
	draw_rect(Rect2(0, -3, width, 3), Color("#714c3d"))
	for x in range(5, int(width) - 2, 10):
		draw_polyline(PackedVector2Array([
			Vector2(x - 5, -2), Vector2(x + 1, -12), Vector2(x + 4, -2)
		]), Color("#d8986a"), 2.0, true)
