@tool
class_name TrailSign
extends Node2D

const TYPE := preload("res://assets/fonts/Inter-Variable.ttf")

@export var directions := "Trail":
	set(value):
		directions = value
		queue_redraw()
@export var branch_sign := false:
	set(value):
		branch_sign = value
		queue_redraw()

func _draw() -> void:
	var width: float = TYPE.get_string_size(directions, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 34
	var left: float = -width / 2.0
	draw_line(Vector2(0, 0), Vector2(0, -57), Color("#56695d"), 6.0, true)
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, -74), Vector2(left + width - 12, -74), Vector2(left + width, -59),
		Vector2(left + width - 12, -44), Vector2(left, -44)
	]), Color("#2d4b48"))
	draw_line(Vector2(left, -74), Vector2(left + width - 12, -74), Color("#80927c"), 1.5, true)
	draw_string(TYPE, Vector2(left + 9, -54), directions, HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
		Color("#ffcb87") if branch_sign else Color("#d9e7d5"))
