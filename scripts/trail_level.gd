class_name TrailLevel
extends Node2D
## The stage scene owns the map. This script connects reusable stage objects.

signal lanterns_changed(collected: int, total: int)
signal checkpoint_activated
signal lantern_collected
signal respawned
signal feedback(text: String)
signal completed

@export var trail_length: float = 10740.0
@export var fall_limit: float = 770.0
@onready var player: Hiker = $Hiker
@onready var camera: Camera2D = $Camera2D
@onready var start: Marker2D = $Trailhead
@onready var shelter: TrailShelter = $Shelter

var progress := TrailProgress.new()
var _respawn_pending: bool = false

func _ready() -> void:
	var ids: Array[StringName] = []
	for child in $Lanterns.get_children():
		var lantern := child as TrailLantern
		if lantern != null:
			ids.append(lantern.lantern_id)
			lantern.touched.connect(_on_lantern_touched)
	progress.begin(ids, start.global_position)
	progress.lanterns_changed.connect(_on_lanterns_changed)
	progress.completed.connect(_on_completed)
	for child in $Checkpoints.get_children():
		var checkpoint := child as TrailCheckpoint
		if checkpoint != null:
			checkpoint.reached.connect(_on_checkpoint_reached.bind(checkpoint))
	for child in $Hazards.get_children():
		var hazard := child as TrailHazard
		if hazard != null:
			hazard.struck.connect(request_respawn)
	shelter.approached.connect(_on_shelter_approached)
	player.place_at(start.global_position)
	_update_camera(1.0)
	shelter.set_progress(0, progress.total())

func _physics_process(delta: float) -> void:
	if player.global_position.y > fall_limit:
		request_respawn()
	_update_camera(1.0 - exp(-delta * 7.0))

func _update_camera(weight: float) -> void:
	var desired: float = clampf(player.global_position.x + 78.0, 640.0, trail_length - 640.0)
	camera.position.x = lerpf(camera.position.x, desired, weight)

func request_respawn() -> void:
	if _respawn_pending or progress.finished:
		return
	_respawn_pending = true
	_respawn.call_deferred()

func _respawn() -> void:
	_respawn_pending = false
	if progress.finished or not is_inside_tree():
		return
	player.place_at(progress.respawn_point)
	_update_camera(1.0)
	respawned.emit()
	feedback.emit("Returned to the checkpoint." if progress.respawn_point != start.global_position else "Back at the trailhead.")

func _on_lantern_touched(lantern: TrailLantern) -> void:
	if progress.collect(lantern.lantern_id):
		lantern.mark_collected()
		lantern_collected.emit()

func _on_lanterns_changed(collected: int, total: int) -> void:
	shelter.set_progress(collected, total)
	lanterns_changed.emit(collected, total)
	if collected == total:
		feedback.emit("All lanterns found. Head to the shelter.")

func _on_checkpoint_reached(point: Vector2, checkpoint: TrailCheckpoint) -> void:
	if point == progress.respawn_point or progress.finished:
		return
	progress.set_checkpoint(point)
	for child in $Checkpoints.get_children():
		if child is TrailCheckpoint:
			child.set_checkpoint_state(child == checkpoint)
	checkpoint_activated.emit()
	feedback.emit("Checkpoint reached.")

func _on_shelter_approached() -> void:
	if progress.finished or progress.enter_shelter():
		return
	var remaining: int = progress.total() - progress.collected_count()
	var noun: String = "lantern" if remaining == 1 else "lanterns"
	feedback.emit("Shelter locked. Find %d more %s." % [remaining, noun])

func _on_completed() -> void:
	player.clear_transient_input()
	completed.emit()
