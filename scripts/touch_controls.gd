class_name TrailTouchControls
extends Control
## Each finger owns its current control. A release only clears that finger.

signal direction_changed(axis: float)
signal jump_requested

const RADIUS: float = 42.0
const LEFT := &"left"
const RIGHT := &"right"
const JUMP := &"jump"

var _active := false
var _held: Dictionary[int, StringName] = {}

func set_active(active: bool) -> void:
	if not active:
		cancel_touches()
	_active = active
	visible = active
	queue_redraw()

func cancel_touches() -> void:
	_held.clear()
	direction_changed.emit(0.0)
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_touches()

func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventScreenTouch:
		if event.pressed and not event.canceled:
			var target: StringName = _target_at(event.position)
			if target.is_empty():
				return
			_held[event.index] = target
			if target == JUMP:
				jump_requested.emit()
		elif _held.has(event.index):
			_held.erase(event.index)
		else:
			return
		_update_hold()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and _held.has(event.index):
		var old_target: StringName = _held[event.index]
		var target: StringName = _target_at(event.position)
		_held[event.index] = target
		if target == JUMP and old_target != JUMP:
			jump_requested.emit()
		_update_hold()
		get_viewport().set_input_as_handled()

func _update_hold() -> void:
	var pressed: Array[StringName] = _held.values()
	direction_changed.emit(float(pressed.has(RIGHT)) - float(pressed.has(LEFT)))
	queue_redraw()

func center_for(action: StringName) -> Vector2:
	match action:
		LEFT:
			return Vector2(76, size.y - 66)
		RIGHT:
			return Vector2(176, size.y - 66)
		_:
			return Vector2(size.x - 78, size.y - 66)

func _target_at(point: Vector2) -> StringName:
	for action: StringName in [LEFT, RIGHT, JUMP]:
		if point.distance_squared_to(center_for(action)) <= RADIUS * RADIUS:
			return action
	return &""

func _draw() -> void:
	for action: StringName in [LEFT, RIGHT, JUMP]:
		var point := center_for(action)
		var active: bool = _held.values().has(action)
		var fill := Color(0.40, 0.54, 0.45, 0.88) if active else Color(0.08, 0.17, 0.20, 0.77)
		var rim := Color("#f0c381") if active else Color("#a1bcb0")
		draw_circle(point, RADIUS, fill, true, -1, true)
		draw_arc(point, RADIUS - 1, 0.0, TAU, 48, rim, 2.0, true)
		if action == JUMP:
			draw_polyline(PackedVector2Array([point + Vector2(-10, 2), point + Vector2(0, -9),
				point + Vector2(10, 2)]), rim, 3.5, true)
			draw_line(point + Vector2(0, -8), point + Vector2(0, 12), rim, 3.5, true)
		else:
			var sign_value: float = -1.0 if action == LEFT else 1.0
			draw_polyline(PackedVector2Array([point + Vector2(-4 * sign_value, -10),
				point + Vector2(8 * sign_value, 0), point + Vector2(-4 * sign_value, 10)]), rim, 4.0, true)
