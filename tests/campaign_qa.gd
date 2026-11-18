extends SceneTree
## Drive every new course with the same movement actions used by the player.

const MAIN := preload("res://scenes/main.tscn")
const FLOOR_TOLERANCE := 3.0

var game: FogTrail
var _checks: int = 0
var _failures: int = 0
var _respawns: int = 0
var _save_file: String

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_save_file = "user://campaign-qa-%d.cfg" % OS.get_process_id()
	_test_save_model()
	game = MAIN.instantiate() as FogTrail
	game.campaign = TrailCampaign.new(_save_file)
	root.add_child(game)
	await _frames(4)
	await _test_campaign()
	_release_input()
	game.go_to_menu()
	if FileAccess.file_exists(_save_file):
		DirAccess.remove_absolute(_save_file)
	await _frames(2)
	print("Campaign QA: %d assertions, %d failures." % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _test_save_model() -> void:
	_check(TrailStages.NAMES.size() == TrailStages.COUNT and TrailStages.SCENES.size() == TrailStages.COUNT,
		"Every stage has a name and a scene.")
	var progress := TrailCampaign.new(_save_file)
	progress.load_progress()
	_check(progress.can_start(1) and not progress.can_start(2) and not progress.can_start(0), "A fresh game opens only stage 1.")
	progress.record_clear(2)
	_check(progress.cleared_count == 0 and not FileAccess.file_exists(_save_file), "A locked stage cannot be cleared out of order.")
	var invalid := ConfigFile.new()
	invalid.set_value(TrailCampaign.SECTION, TrailCampaign.CLEAR_KEY, "malformed")
	invalid.save(_save_file)
	progress.load_progress()
	_check(progress.cleared_count == 0, "An invalid save value falls back to the opening stage.")
	progress.record_clear(1)
	var reopened := TrailCampaign.new(_save_file)
	reopened.load_progress()
	_check(reopened.cleared_count == 1 and reopened.can_start(2) and not reopened.can_start(3), "A reopened save preserves the next unlock.")
	progress.record_clear(2)
	progress.record_clear(1)
	reopened.load_progress()
	_check(reopened.cleared_count == 2, "Replacing the save and replaying an older stage preserves the highest clear.")
	DirAccess.remove_absolute(_save_file)

func _test_campaign() -> void:
	_press_button("Stage Map")
	_check(game.mode == FogTrail.Mode.MAP, "Stage Map opens from the title screen.")
	_check(_map_card(1) != null and not _map_card(1).disabled, "Stage 1 can be selected on the map.")
	for stage in range(2, TrailStages.COUNT + 1):
		_check(_map_card(stage) != null and _map_card(stage).disabled, "Stage %d is locked on a fresh map." % stage)
	game.start_level(10)
	_check(game.mode == FogTrail.Mode.MAP and not is_instance_valid(game.level), "A locked launch request leaves the map intact.")
	_map_card(1).pressed.emit()
	await _frames(6)
	_check(game.current_stage == 1, "Selecting the first map card opens the original trail.")
	# The separate original-trail suite plays this long route from start to finish.
	for child in game.level.get_node("Lanterns").get_children():
		var lantern := child as TrailLantern
		game.level.player.place_at(lantern.position + Vector2(0, 26))
		await _frames(8)
	game.level.player.place_at(game.level.shelter.position - Vector2(0, 2))
	await _frames(8)
	if not _check(game.mode == FogTrail.Mode.COMPLETE and game.campaign.cleared_count == 1,
			"The original shelter clears stage 1 and unlocks stage 2."):
		return

	var previous_gap: float = 0.0
	for stage in range(2, TrailStages.COUNT + 1):
		if not _press_button("Next Stage"):
			return
		await _frames(8)
		if not _check(game.current_stage == stage and game.mode == FogTrail.Mode.PLAYING,
				"Next Stage opens stage %d." % stage):
			return
		_check(game.level.progress.total() == 3 and game.level.progress.collected_count() == 0,
			"Stage %d has three fresh lanterns." % stage)
		_check(game.level.progress.respawn_point == game.level.start.global_position, "Stage %d begins at its own trailhead." % stage)
		if stage < TrailStages.COUNT:
			_check(not game.campaign.can_start(stage + 1), "Only completed stages unlock their successor.")
		var gap: float = _largest_gap()
		_check(gap > previous_gap, "Stage %d increases the longest gap across the new courses." % stage)
		previous_gap = gap
		if not await _walk_course(1):
			return
		if not _check(game.campaign.cleared_count == stage and game.campaign.save_error == OK,
				"Stage %d activates the shelter and saves its clear." % stage):
			return
		print("PASS: stage %02d %s — all lanterns and shelter reached through movement input (max gap %d)." %
			[stage, TrailStages.NAMES[stage - 1], int(gap)])

	_check(_find_label(game.hud, "To be continued…"), "The tenth shelter shows the campaign finale.")
	_check(_find_button(game.hud, "Next Stage") == null and not game.campaign.can_start(11), "The finale cannot advance to stage 11.")
	_press_button("Play Again")
	await _frames(8)
	_check(game.current_stage == 10 and game.level.progress.collected_count() == 0, "Replay resets the tenth attempt without changing the selected stage.")
	game.level.player.place_at(game.level.shelter.position - Vector2(0, 2))
	await _frames(8)
	_check(game.mode == FogTrail.Mode.PLAYING, "A fresh summit shelter waits for its lanterns.")
	if not await _walk_course(-1):
		return
	_check(game.level.progress.collected_count() == 3, "All summit lanterns are reachable by backtracking from the locked shelter.")
	if not await _walk_course(1):
		return
	_check(_find_label(game.hud, "To be continued…"), "The summit can be completed again after backtracking.")

	root.go_back_requested.emit()
	_check(game.mode == FogTrail.Mode.MAP and game.campaign.cleared_count == TrailStages.COUNT,
		"System Back from the finale opens the map with all clears intact.")
	root.go_back_requested.emit()
	game.queue_free()
	await _frames(2)
	game = MAIN.instantiate() as FogTrail
	game.campaign = TrailCampaign.new(_save_file)
	root.add_child(game)
	await _frames(4)
	_check(game.campaign.cleared_count == TrailStages.COUNT, "Reopening the game restores the complete campaign.")
	_press_button("Stage Map")
	for stage in range(1, TrailStages.COUNT + 1):
		_check(_map_card(stage) != null and not _map_card(stage).disabled, "Completed stage %d remains replayable." % stage)
	_map_card(4).pressed.emit()
	await _frames(6)
	_check(game.current_stage == 4 and game.campaign.cleared_count == TrailStages.COUNT, "Replaying an earlier stage preserves the completed campaign.")
	print("PASS: stage map, summit backtracking, finale, and reload from save.")

func _walk_course(direction: int) -> bool:
	var ground: Array[Node] = game.level.get_node("Terrain").get_children()
	if direction < 0:
		ground.reverse()
	var action: StringName = &"move_right" if direction > 0 else &"move_left"
	var player: Hiker = game.level.player
	_respawns = 0
	var on_respawn := func() -> void: _respawns += 1
	game.level.respawned.connect(on_respawn)
	for index in range(ground.size()):
		var platform := ground[index] as TrailPlatform
		for node in game.level.get_node("Hazards").get_children():
			var hazard := node as TrailHazard
			if hazard.position.x < platform.position.x or hazard.position.x >= platform.position.x + platform.size.x:
				continue
			var entry: float = hazard.position.x if direction > 0 else hazard.position.x + hazard.width
			var exit: float = hazard.position.x + hazard.width if direction > 0 else hazard.position.x
			if not await _drive_to(player, entry - direction * 34.0, action, direction):
				return _route_failed(player, platform, direction, "approaching thorns")
			if not await _jump_and_land(player, platform, exit + direction * 27.0, exit + direction * 14.0, action, direction):
				return _route_failed(player, platform, direction, "jumping over thorns")
		if index == ground.size() - 1:
			var end: float = game.level.shelter.position.x + 2.0 if direction > 0 else game.level.start.position.x
			if not await _drive_to(player, end, action, direction):
				return _route_failed(player, platform, direction, "reaching the trail endpoint")
			break
		var next := ground[index + 1] as TrailPlatform
		var lip: float = platform.position.x + platform.size.x if direction > 0 else platform.position.x
		var entrance: float = next.position.x if direction > 0 else next.position.x + next.size.x
		if not await _drive_to(player, lip - direction * 6.0, action, direction):
			return _route_failed(player, platform, direction, "approaching the gap")
		var aim: float = entrance + direction * minf(32.0, next.size.x * 0.43)
		if not await _jump_and_land(player, next, aim, entrance + direction * 3.0, action, direction):
			return _route_failed(player, next, direction, "landing across the gap")
	_release_input()
	game.level.respawned.disconnect(on_respawn)
	await _frames(5)
	if direction > 0:
		return _check(game.mode == FogTrail.Mode.COMPLETE and game.level.progress.collected_count() == 3,
			"Stage %d reaches completion with all three lanterns." % game.current_stage)
	return _check(game.mode == FogTrail.Mode.PLAYING and absf(player.position.x - game.level.start.position.x) < 30.0,
		"Backtracking reaches the summit trailhead.")

func _drive_to(player: Hiker, target: float, action: StringName, direction: int) -> bool:
	Input.action_press(action)
	for frame in range(160):
		if direction * (player.position.x - target) >= 0.0 or game.mode == FogTrail.Mode.COMPLETE:
			return true
		if _respawns > 0:
			break
		await _frames(1)
	return false

func _jump_and_land(player: Hiker, landing: TrailPlatform, aim: float, minimum: float,
		action: StringName, direction: int) -> bool:
	Input.action_press(&"jump")
	await _frames(2)
	Input.action_release(&"jump")
	for frame in range(100):
		if _respawns > 0:
			break
		if direction * (player.position.x - aim) >= 0.0:
			Input.action_release(action)
		var at_height: bool = absf(player.position.y - landing.position.y) < FLOOR_TOLERANCE
		var on_platform: bool = player.position.x > landing.position.x and player.position.x < landing.position.x + landing.size.x
		if player.is_on_floor() and at_height and on_platform and direction * (player.position.x - minimum) >= 0.0:
			return true
		await _frames(1)
	return false

func _largest_gap() -> float:
	var prior: TrailPlatform
	var gap := 0.0
	for node in game.level.get_node("Terrain").get_children():
		var platform := node as TrailPlatform
		if prior != null:
			gap = maxf(gap, platform.position.x - prior.position.x - prior.size.x)
		prior = platform
	return gap

func _route_failed(player: Hiker, platform: TrailPlatform, direction: int, step: String) -> bool:
	_release_input()
	return _check(false, "Stage %d direction %d at %s (%s), player %s, respawns %d." %
		[game.current_stage, direction, platform.name, step, player.position, _respawns])

func _map_card(stage: int) -> Button:
	return game.hud._sheet.get_node_or_null("Stage%d" % stage) as Button

func _find_button(parent: Node, caption: String) -> Button:
	if parent is Button and parent.text == caption:
		return parent
	for node in parent.get_children():
		var button := _find_button(node, caption)
		if button != null:
			return button
	return null

func _find_label(parent: Node, caption: String) -> bool:
	if parent is Label and parent.text == caption:
		return true
	for node in parent.get_children():
		if _find_label(node, caption):
			return true
	return false

func _press_button(caption: String) -> bool:
	var button := _find_button(game.hud._sheet, caption)
	if not _check(button != null and not button.disabled, "The %s button is enabled." % caption):
		return false
	button.pressed.emit()
	return true

func _check(condition: bool, detail: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: " + detail)
	return condition

func _release_input() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"jump")

func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
