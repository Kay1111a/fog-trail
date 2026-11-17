extends SceneTree
## Run with a display. Captures the rendered menu, trail, touch layouts, and pause screen.

var failed := false
var output_path := ""

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	output_path = OS.get_environment("FOG_QA_SHOTS")
	if output_path.is_empty():
		output_path = "user://qa_screenshots"
	var directory := ProjectSettings.globalize_path(output_path)
	if not _verify(DirAccess.make_dir_recursive_absolute(directory) == OK, "Screenshot directory is available."):
		quit(1)
		return
	var game := load("res://scenes/main.tscn").instantiate() as FogTrail
	game.campaign = TrailCampaign.new("")
	root.add_child(game)
	await _frames(8)
	await _snapshot("menu")
	_key(KEY_ENTER, true)
	await _frames(2)
	_key(KEY_ENTER, false)
	await _frames(10)
	if not _verify(game.mode == FogTrail.Mode.PLAYING, "Enter activates the focused Play button."):
		quit(1)
		return
	var start_position: Vector2 = game.level.player.position
	_key(KEY_D, true)
	await _frames(10)
	_key(KEY_SPACE, true)
	await _frames(10)
	_key(KEY_SPACE, false)
	_key(KEY_D, false)
	var current_position: Vector2 = game.level.player.position
	_verify(current_position.x > start_position.x + 30 and current_position.y < start_position.y - 35,
		"Physical D and Space move and jump in the rendered game.")
	await _frames(32)
	game.level.player.place_at(Vector2(1503, 542))
	await _frames(20)
	await _snapshot("trail")
	game.level.player.place_at(Vector2(1600, 542))
	await _frames(9)
	_verify(game.level.progress.collected_count() == 1 and game.sounds.playing,
		"Lantern collision updates progress and starts its audio cue.")
	game.use_touch = true
	game.touch.set_active(true)
	for viewport_size: Vector2i in [Vector2i(854, 480), Vector2i(1180, 540)]:
		root.size = viewport_size
		await _frames(12)
		var mobile_size: Vector2 = game.touch.size
		var left: Vector2 = game.touch.center_for(&"left")
		var jump: Vector2 = game.touch.center_for(&"jump")
		_verify(left.x > 42 and jump.x < mobile_size.x - 42 and jump.y < mobile_size.y - 42,
			"Movement and jump circles fit after landscape resize to %s." % str(viewport_size))
		await _snapshot("touch-%s" % str(viewport_size.x))
	_key(KEY_ESCAPE, true)
	await _frames(2)
	_key(KEY_ESCAPE, false)
	await _frames(6)
	_verify(game.mode == FogTrail.Mode.PAUSED and not game.touch.visible, "Physical Escape pauses and clears touch controls.")
	await _snapshot("pause")
	game.open_stage_map()
	for viewport_size: Vector2i in [Vector2i(854, 480), Vector2i(1180, 540)]:
		root.size = viewport_size
		await _frames(12)
		var visible_rect: Rect2 = game.hud.get_global_rect()
		var all_fit := true
		for stage in range(1, TrailStages.COUNT + 1):
			var card := game.hud._sheet.get_node("Stage%d" % stage) as Button
			all_fit = all_fit and visible_rect.encloses(card.get_global_rect())
		_verify(all_fit, "The ten stage cards fit in the landscape view at %s." % str(viewport_size))
		await _snapshot("stage-map-%s" % str(viewport_size.x))
	game.go_to_menu()
	await _frames(6)
	quit(1 if failed else 0)

func _snapshot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var output := output_path.path_join(name + ".png")
	var bitmap := root.get_texture().get_image()
	_verify(bitmap != null and not bitmap.is_empty() and bitmap.save_png(output) == OK, "Rendered " + name + ".")

func _verify(ok: bool, text: String) -> bool:
	print(("PASS: " if ok else "FAIL: ") + text)
	failed = failed or not ok
	return ok

func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)

func _frames(count: int) -> void:
	for n in range(count):
		await physics_frame
