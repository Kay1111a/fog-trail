class_name Hiker
extends CharacterBody2D
## The origin sits at the hiker's feet. Assign input through the shared Input Map.

@export_range(100.0, 500.0) var move_speed: float = 248.0
@export_range(100.0, 1000.0) var jump_strength: float = 564.0
@export_range(200.0, 2500.0) var gravity: float = 1440.0
@export_range(0.0, 0.25) var coyote_time: float = 0.10
@export_range(0.0, 0.25) var jump_buffer: float = 0.12

var touch_axis: float = 0.0
var _touch_jump: bool = false
var _coyote_left: float = 0.0
var _buffer_left: float = 0.0
var _facing: float = 1.0
var _stride: float = 0.0
var _step: float = 0.0
var _coat_edge := _rounded_fill(Color("#162a32"))
var _coat := _rounded_fill(Color("#e1a85f"))
var _pack := _rounded_fill(Color("#435d56"))

func request_touch_jump() -> void:
	_touch_jump = true

func clear_transient_input() -> void:
	touch_axis = 0.0
	_touch_jump = false
	_buffer_left = 0.0
	_coyote_left = 0.0

func place_at(point: Vector2) -> void:
	global_position = point
	velocity = Vector2.ZERO
	clear_transient_input()
	reset_physics_interpolation()

func _physics_process(delta: float) -> void:
	var grounded: bool = is_on_floor()
	if grounded:
		_coyote_left = coyote_time
	else:
		_coyote_left = maxf(0.0, _coyote_left - delta)
		velocity.y = minf(velocity.y + gravity * delta, 920.0)

	var requested: bool = _touch_jump or Input.is_action_just_pressed(&"jump")
	if requested:
		_buffer_left = jump_buffer
	_touch_jump = false
	if (requested or _buffer_left > 0.0) and (grounded or _coyote_left > 0.0):
		velocity.y = -jump_strength
		_buffer_left = 0.0
		_coyote_left = 0.0
	else:
		_buffer_left = maxf(0.0, _buffer_left - delta)

	var direction: float = clampf(Input.get_axis(&"move_left", &"move_right") + touch_axis, -1.0, 1.0)
	velocity.x = move_toward(velocity.x, direction * move_speed, 2060.0 * delta)
	if not is_zero_approx(direction):
		_facing = signf(direction)
	move_and_slide()

	_stride += absf(velocity.x) * delta * 0.067
	_step = sin(_stride) * minf(absf(velocity.x) / move_speed, 1.0) if is_on_floor() else -0.42
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(_facing, 1))
	var jacket_shade := Color("#ae6f46")
	var boots := Color("#1b2830")
	var edge := Color("#152932")
	var step_a := Vector2(-6.0 + _step * 8.0, -2.0 - maxf(_step * 4.0, 0.0))
	var step_b := Vector2(6.0 - _step * 8.0, -2.0 - maxf(-_step * 4.0, 0.0))
	draw_line(Vector2(-4, -16), step_a, Color("#52605a"), 7.0, true)
	draw_line(Vector2(3, -17), step_b, Color("#64716a"), 7.0, true)
	draw_line(step_a + Vector2(-3, 0), step_a + Vector2(4, 0), boots, 5.0, true)
	draw_line(step_b + Vector2(-2, 0), step_b + Vector2(5, 0), boots, 5.0, true)
	draw_style_box(_coat_edge, Rect2(-12, -34, 24, 24))
	draw_style_box(_coat, Rect2(-10, -33, 19, 21))
	draw_line(Vector2(2, -30), Vector2(7, -19) + Vector2(_step * 3.0, 0), jacket_shade, 5.0, true)
	draw_style_box(_pack, Rect2(-16, -35, 9, 19))
	draw_line(Vector2(-13, -30), Vector2(-13, -19), Color("#88a391"), 2.0, true)
	draw_circle(Vector2(2, -40), 9.0, edge, true, -1.0, true)
	draw_circle(Vector2(3, -40), 7.0, Color("#dcb996"), true, -1.0, true)
	draw_circle(Vector2(1, -44), 8.0, Color("#d19458"), true, -1.0, true)
	draw_line(Vector2(-6, -40), Vector2(13, -40), Color("#f1bd72"), 3.0, true)
	draw_circle(Vector2(8, -37), 1.25, edge, true, -1.0, true)
	draw_line(Vector2(-5, -34), Vector2(9, -34), Color("#e8d2a5"), 2.0, true)

func _rounded_fill(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	return style
