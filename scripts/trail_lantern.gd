@tool
class_name TrailLantern
extends Area2D

signal touched(lantern: TrailLantern)
@export var lantern_id: StringName = &"lantern"
var _taken := false
var _phase := 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_phase = fposmod(_phase + delta, TAU * 4.0)
	queue_redraw()

func mark_collected() -> void:
	_taken = true
	hide()
	set_deferred("monitoring", false)
	set_process(false)

func _on_body_entered(body: Node2D) -> void:
	if body is Hiker and not _taken:
		touched.emit(self)

func _draw() -> void:
	var center := Vector2(0, sin(_phase * 2.0) * 3.0)
	for i in range(12, 0, -1):
		var amount: float = float(i) / 12.0
		draw_circle(center, 17.0 + amount * 43.0, Color(1.0, 0.64, 0.26, 0.017 + (1.0 - amount) * 0.014), true, -1.0, true)
	draw_arc(center + Vector2(0, -13), 6.5, PI, TAU, 12, Color("#f4d68b"), 2.0, true)
	draw_rect(Rect2(center + Vector2(-10, -12), Vector2(20, 24)), Color("#563c30"))
	draw_rect(Rect2(center + Vector2(-7, -9), Vector2(14, 18)), Color("#ffcf73"))
	draw_rect(Rect2(center + Vector2(-3, -5), Vector2(5, 11)), Color("#fff0b3"))
	draw_line(center + Vector2(-11, 11), center + Vector2(11, 11), Color("#f5bd6b"), 2.0, true)
	draw_line(center + Vector2(-11, -12), center + Vector2(11, -12), Color("#f6d895"), 2.0, true)
	for i in range(3):
		var turn: float = _phase * 0.8 + float(i) * 2.1
		draw_circle(center + Vector2(cos(turn) * (28 + i * 5), sin(turn * 2.0) * 11 - 10),
			1.6, Color(1, 0.82, 0.43, 0.35), true, -1.0, true)
