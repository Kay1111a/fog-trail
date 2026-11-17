class_name TrailProgress
extends RefCounted
## Tracks a single attempt. Respawning reads the checkpoint without resetting progress.

signal lanterns_changed(collected: int, total: int)
signal checkpoint_changed
signal completed

var respawn_point := Vector2.ZERO
var finished := false
var _lanterns: Dictionary[StringName, bool] = {}
var _collected_count := 0

func begin(ids: Array[StringName], spawn: Vector2) -> void:
	_lanterns.clear()
	for id in ids:
		assert(not id.is_empty() and not _lanterns.has(id), "Lanterns need unique, nonempty IDs.")
		_lanterns[id] = false
	_collected_count = 0
	respawn_point = spawn
	finished = false

func collected_count() -> int:
	return _collected_count

func total() -> int:
	return _lanterns.size()

func collect(id: StringName) -> bool:
	if finished or not _lanterns.has(id) or _lanterns[id]:
		return false
	_lanterns[id] = true
	_collected_count += 1
	lanterns_changed.emit(_collected_count, total())
	return true

func set_checkpoint(point: Vector2) -> void:
	if finished or point == respawn_point:
		return
	respawn_point = point
	checkpoint_changed.emit()

func enter_shelter() -> bool:
	if finished or _collected_count != total():
		return false
	finished = true
	completed.emit()
	return true
