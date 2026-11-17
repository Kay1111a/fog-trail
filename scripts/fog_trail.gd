class_name FogTrail
extends Node

enum Mode { MAIN, CONTROLS, PLAYING, PAUSED, COMPLETE, MAP }

const PICKUP_SOUND := preload("res://assets/audio/lantern.wav")
const CHECKPOINT_SOUND := preload("res://assets/audio/checkpoint.wav")
const COMPLETE_SOUND := preload("res://assets/audio/complete.wav")

@onready var backdrop: ForestBackdrop = $Backdrop/ForestBackdrop
@onready var hud: TrailHUD = $Interface/HUD
@onready var touch: TrailTouchControls = $Interface/TouchControls
@onready var sounds: AudioStreamPlayer = $Sounds
@onready var world: Node2D = $World

var mode: Mode = Mode.MAIN
var level: TrailLevel
var use_touch := false
var campaign := TrailCampaign.new()
var current_stage: int = 1

func _ready() -> void:
	use_touch = OS.has_feature("mobile") or "--touch-controls" in OS.get_cmdline_user_args()
	campaign.load_progress()
	hud.play_requested.connect(_continue_campaign)
	hud.restart_requested.connect(_restart_level)
	hud.map_requested.connect(open_stage_map)
	hud.stage_requested.connect(start_level)
	hud.menu_requested.connect(go_to_menu)
	hud.controls_requested.connect(_open_controls)
	hud.pause_requested.connect(pause_game)
	hud.resume_requested.connect(resume_game)
	touch.direction_changed.connect(_set_touch_axis)
	touch.jump_requested.connect(_jump_on_touch)
	go_to_menu()

func _process(_delta: float) -> void:
	if is_instance_valid(level):
		backdrop.travel = level.camera.position.x - 640.0
	else:
		backdrop.travel = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"pause"):
		return
	match mode:
		Mode.PLAYING:
			pause_game()
		Mode.PAUSED:
			resume_game()
		Mode.CONTROLS, Mode.MAP:
			go_to_menu()
		Mode.COMPLETE:
			open_stage_map()
		_:
			return
	get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and mode == Mode.PLAYING and is_node_ready():
		pause_game()

func _continue_campaign() -> void:
	if campaign.cleared_count == TrailStages.COUNT:
		open_stage_map()
	else:
		start_level(campaign.next_available())

func _restart_level() -> void:
	start_level(current_stage)

func start_level(stage: int = 1) -> void:
	if not campaign.can_start(stage):
		return
	_clear_level()
	current_stage = stage
	mode = Mode.PLAYING
	get_tree().paused = false
	backdrop.menu_view = false
	level = TrailStages.SCENES[stage - 1].instantiate() as TrailLevel
	world.add_child(level)
	level.lanterns_changed.connect(hud.set_lanterns)
	level.feedback.connect(hud.show_feedback)
	level.lantern_collected.connect(_play_cue.bind(PICKUP_SOUND))
	level.checkpoint_activated.connect(_play_cue.bind(CHECKPOINT_SOUND))
	level.respawned.connect(touch.cancel_touches)
	level.completed.connect(_finish)
	hud.begin_stage(stage, level.progress.total(), use_touch)
	touch.set_active(use_touch)

func _open_controls() -> void:
	mode = Mode.CONTROLS
	hud.show_controls()

func go_to_menu() -> void:
	_clear_level()
	mode = Mode.MAIN
	get_tree().paused = false
	backdrop.menu_view = true
	hud.show_main_menu(campaign.cleared_count)

func open_stage_map() -> void:
	_clear_level()
	mode = Mode.MAP
	get_tree().paused = false
	backdrop.menu_view = true
	hud.show_stage_map(campaign)

func pause_game() -> void:
	if mode != Mode.PLAYING:
		return
	mode = Mode.PAUSED
	_quiet_controls()
	get_tree().paused = true
	hud.show_pause()

func resume_game() -> void:
	if mode != Mode.PAUSED:
		return
	mode = Mode.PLAYING
	get_tree().paused = false
	hud.show_stage()
	touch.set_active(use_touch)

func _finish() -> void:
	if mode != Mode.PLAYING:
		return
	mode = Mode.COMPLETE
	_quiet_controls()
	get_tree().paused = true
	_play_cue(COMPLETE_SOUND)
	campaign.record_clear(current_stage)
	hud.show_complete(current_stage, campaign.save_error != OK)

func _clear_level() -> void:
	_quiet_controls()
	sounds.stop()
	sounds.stream = null
	if is_instance_valid(level):
		world.remove_child(level)
		level.queue_free()
		level = null

func _quiet_controls() -> void:
	touch.set_active(false)
	if is_instance_valid(level):
		level.player.clear_transient_input()

func _set_touch_axis(value: float) -> void:
	if is_instance_valid(level):
		level.player.touch_axis = value

func _jump_on_touch() -> void:
	if mode == Mode.PLAYING and is_instance_valid(level):
		level.player.request_touch_jump()

func _play_cue(clip: AudioStream) -> void:
	if DisplayServer.get_name() == "headless":
		return
	sounds.stream = clip
	sounds.play()
