@tool
class_name TrailPlatform
extends StaticBody2D
## Move the instance to position its top-left edge. Width and height update its collision.

@export var size := Vector2(260, 70):
	set(value):
		size = Vector2(maxf(24.0, value.x), maxf(14.0, value.y))
		if is_node_ready():
			_refresh_shape()
			queue_redraw()
@export var bridge := false:
	set(value):
		bridge = value
		queue_redraw()

func _ready() -> void:
	_refresh_shape()

func _refresh_shape() -> void:
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	$CollisionShape2D.shape = rectangle
	$CollisionShape2D.position = size * 0.5

func _draw() -> void:
	var width: float = size.x
	var height: float = size.y
	if bridge:
		draw_rect(Rect2(Vector2.ZERO, size), Color("#303939"))
		draw_rect(Rect2(0, 1, width, 10), Color("#8d7958"))
		draw_rect(Rect2(0, 0, width, 3), Color("#bca17a"))
		draw_rect(Rect2(0, height - 4, width, 4), Color("#202e33"))
		for x in range(12, int(width), 23):
			draw_line(Vector2(x, 4), Vector2(x, height - 3), Color("#4b4a3d"), 2)
			draw_circle(Vector2(x + 4, 6), 1.2, Color("#b4a079"))
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color("#253d40"))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, 8), Vector2(width, 8), Vector2(width, height),
		Vector2(width * 0.63, height), Vector2(width * 0.59, height * 0.65),
		Vector2(width * 0.32, height * 0.78), Vector2(0, height)
	]), Color("#1e3339"))
	draw_rect(Rect2(0, 0, width, 9), Color("#466459"))
	draw_rect(Rect2(0, 0, width, 2), Color("#85a28a"))
	draw_line(Vector2(0, 0), Vector2(0, height), Color("#263438"), 2)
	draw_line(Vector2(width, 1), Vector2(width, height), Color("#172b31"), 3)
	for x in range(13, int(width) - 10, 29):
		var hash_value: int = (x * 79 + int(position.x) * 13) % 17
		var ridge_y: float = 13.0 + float(hash_value) * 0.44
		draw_line(Vector2(x, ridge_y), Vector2(x + 8 + hash_value, ridge_y + 3), Color("#3c5050"), 1.5, true)
		if hash_value % 3 == 0:
			draw_line(Vector2(x, 0), Vector2(x - 4, -4 - hash_value % 5), Color("#78917b"), 1.7, true)
			draw_line(Vector2(x, 0), Vector2(x + 4, -5), Color("#839e85"), 1.5, true)
