extends SceneTree
## Run with Godot's --headless --fixed-fps 60 options for deterministic physics steps.

const MAIN := preload("res://scenes/main.tscn")
const TERRAIN := preload("res://scenes/trail_platform.tscn")
const HIKER := preload("res://scenes/hiker.tscn")
const EPSILON: float = 2.0

var game: FogTrail
var checks := 0
var failures: Array[String] = []
var feedback := ""
var wins := 0
var respawns := 0

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	_test_progress()
	_test_input_map()
	await _test_collision_bench()
	game = MAIN.instantiate() as FogTrail
	game.campaign = TrailCampaign.new("")
	root.add_child(game)
	await _frames(3)
	await _test_pickup_display()
	await _test_menus_and_resets()
	await _test_touch()
	await _test_two_playthroughs()
	await _test_all_lanterns_reachable_after_shelter()
	_release_inputs()
	game.go_to_menu()
	await _frames(2)
	print("Fog Trail QA: %d assertions, %d failures." % [checks, failures.size()])
	for failure in failures:
		printerr("FAIL: " + failure)
	quit(0 if failures.is_empty() else 1)

func _check(condition: bool, message: String) -> bool:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("CHECK FAILED: " + message)
	return condition

func _test_progress() -> void:
	var model := TrailProgress.new()
	var ids: Array[StringName] = [&"crossing", &"ridge", &"hollow"]
	var orders: Array[Array] = [
		[0, 1, 2], [0, 2, 1], [1, 0, 2], [1, 2, 0], [2, 0, 1], [2, 1, 0]
	]
	for order: Array in orders:
		model.begin(ids, Vector2(20, 40))
		_check(model.collected_count() == 0 and model.total() == 3, "An attempt starts with zero of three.")
		_check(not model.collect(&"unknown"), "An unknown ID cannot increase the count.")
		_check(not model.enter_shelter(), "Shelter must be locked at zero.")
		model.set_checkpoint(Vector2(32, 58))
		_check(model.respawn_point == Vector2(32, 58), "Checkpoint replaces initial spawn.")
		for index in range(3):
			var id: StringName = ids[order[index]]
			_check(model.collect(id), "Collect id %s in order %s." % [id, order])
			_check(not model.collect(id), "Duplicate lantern contacts cannot count.")
			_check(model.collected_count() == index + 1, "HUD source increments by exactly one.")
			if index < 2:
				_check(not model.enter_shelter(), "Shelter must remain locked until all three.")
		_check(model.enter_shelter(), "Shelter can complete with all lanterns.")
		_check(not model.enter_shelter(), "Shelter can only complete once.")
		model.set_checkpoint(Vector2(0, 0))
		_check(model.respawn_point == Vector2(32, 58), "Checkpoint is frozen after completion.")
	print("PASS: game state in all six lantern orders, duplicate touches, gating and reset.")

func _test_input_map() -> void:
	for mapping: Array in [[KEY_A, &"move_left"], [KEY_LEFT, &"move_left"],
		[KEY_D, &"move_right"], [KEY_RIGHT, &"move_right"], [KEY_SPACE, &"jump"], [KEY_ESCAPE, &"pause"]]:
		var event := InputEventKey.new()
		event.physical_keycode = mapping[0]
		_check(InputMap.event_is_action(event, mapping[1]), "Physical key %s maps to %s." % [mapping[0], mapping[1]])

func _test_collision_bench() -> void:
	var bench := Node2D.new()
	root.add_child(bench)
	for spec: Array in [[Vector2(0, 500), Vector2(500, 48)],
		[Vector2(295, 378), Vector2(26, 122)], [Vector2(67, 372), Vector2(132, 27)]]:
		var platform := TERRAIN.instantiate() as TrailPlatform
		platform.position = spec[0]
		platform.size = spec[1]
		bench.add_child(platform)
	var player := HIKER.instantiate() as Hiker
	bench.add_child(player)
	player.place_at(Vector2(110, 498))
	await _frames(12)
	_check(player.is_on_floor(), "Player settles on the floor collision.")
	Input.action_press(&"jump")
	await _frames(8)
	Input.action_release(&"jump")
	_check(player.position.y < 498, "Jump raises the player.")
	await _frames(24)
	_check(player.is_on_floor() and absf(player.position.y - 500) < EPSILON, "Head hits ceiling and player lands.")
	Input.action_press(&"move_right")
	await _frames(64)
	Input.action_release(&"move_right")
	_check(player.is_on_wall() and player.position.x <= 285, "Solid wall prevents crossing.")
	Input.action_press(&"move_left")
	await _frames(16)
	Input.action_release(&"move_left")
	_check(player.position.x < 250, "Player can move away from a wall.")
	player.jump_buffer = 0.0
	player.coyote_time = 0.0
	await _frames(12)
	Input.action_press(&"jump")
	await _frames(6)
	Input.action_release(&"jump")
	_check(player.position.y < 490.0, "Disabling the jump buffer still permits grounded jumping.")
	bench.queue_free()
	await _frames(2)
	print("PASS: floor, ceiling, wall and bidirectional movement.")

func _test_pickup_display() -> void:
	_press_button("Play")
	await _frames(8)
	var lanterns: Array[TrailLantern] = [
		game.level.get_node("Lanterns/RidgeLantern") as TrailLantern,
		game.level.get_node("Lanterns/HollowLantern") as TrailLantern,
		game.level.get_node("Lanterns/CrossingLantern") as TrailLantern
	]
	var landings: Array[Vector2] = [Vector2(4825, 353), Vector2(6526, 628), Vector2(1600, 543)]
	_check(game.hud._number.text == "Lanterns 0/3", "The HUD starts at 0/3.")
	for index in range(lanterns.size()):
		await _relocate(landings[index])
		_check(game.hud._number.text == "Lanterns %d/3" % (index + 1), "The HUD updates on pickup in a different order.")
		_check(not lanterns[index].visible, "The collected lantern is hidden.")
	game.go_to_menu()
	print("PASS: scene contacts in ridge, hollow, crossing order hide each lantern and update the HUD from 0/3 to 3/3.")

func _test_menus_and_resets() -> void:
	_check(game.mode == FogTrail.Mode.MAIN, "Startup reaches the main menu.")
	_press_button("Controls")
	_check(game.mode == FogTrail.Mode.CONTROLS, "Controls screen opens.")
	_press_button("Back")
	_check(game.mode == FogTrail.Mode.MAIN, "Controls screen returns to main.")
	_press_button("Play")
	await _frames(9)
	_watch_level()
	_assert_reset("Play")

	var stage: TrailLevel = game.level
	var start: Vector2 = stage.start.global_position
	await _relocate(Vector2(652, 620))
	await _frames(39)
	_check(stage.player.position.distance_to(start) < 5.0, "A pit returns the player to the trailhead.")
	await _relocate(Vector2(1141, 573))
	await _frames(12)
	_check(stage.player.position.distance_to(start) < 5.0, "A thorn hazard returns the player to the trailhead.")
	await _relocate(Vector2(1600, 543))
	_check(stage.progress.collected_count() == 1, "First lantern collision updates progress.")
	await _relocate(Vector2(4030, 544))
	_check(stage.progress.respawn_point.distance_to(Vector2(4042, 545)) < EPSILON, "Checkpoint collision records its spawn marker.")
	for iteration in range(3):
		await _relocate(Vector2(5880, 516))
		await _frames(11)
		_check(stage.player.position.distance_to(stage.progress.respawn_point) < 5.0,
			"Hazard respawn %d lands at checkpoint." % (iteration + 1))
		_check(stage.progress.collected_count() == 1, "Respawn retains collected lanterns.")
	await _relocate(Vector2(6602, 738))
	await _frames(24)
	_check(stage.player.position.distance_to(stage.progress.respawn_point) < 5.0, "A pit after the checkpoint returns the player there.")
	Input.action_press(&"move_left")
	await _frames(12)
	Input.action_release(&"move_left")
	_check(stage.player.position.x < stage.progress.respawn_point.x - 20 and stage.progress.collected_count() == 1,
		"Movement works immediately after a checkpoint respawn and the lantern persists.")
	await _relocate(Vector2(1600, 543))
	_check(stage.progress.collected_count() == 1, "Previously collected lantern cannot count again.")
	Input.action_press(&"move_right")
	await _frames(4)
	await _send_escape()
	var paused_position: Vector2 = stage.player.position
	await _frames(19)
	_check(game.mode == FogTrail.Mode.PAUSED and stage.player.position == paused_position, "Escape pauses a moving character.")
	_check(stage.progress.collected_count() == 1, "Pause preserves progress.")
	Input.action_release(&"move_right")
	_press_button("Resume")
	await _frames(4)
	_check(game.mode == FogTrail.Mode.PLAYING, "Resume returns to gameplay.")
	var ground: float = stage.player.position.y
	Input.action_press(&"jump")
	await _frames(8)
	Input.action_release(&"jump")
	await _send_escape()
	var paused_jump: Vector2 = stage.player.position
	await _frames(12)
	_check(paused_jump.y < ground - 30 and stage.player.position == paused_jump, "Pause also freezes a jump in flight.")
	_press_button("Restart Level")
	await _frames(8)
	_watch_level()
	_assert_reset("Restart Level")

	for count in range(3):
		if count == 1:
			await _relocate(Vector2(1600, 543))
		elif count == 2:
			await _relocate(Vector2(4825, 353))
		await _relocate(Vector2(10524, 546))
		_check(game.mode == FogTrail.Mode.PLAYING, "Shelter stays locked with %d lanterns." % count)
		_check(str(3 - count) in feedback and "locked" in feedback.to_lower(),
			"Locked shelter explains the missing count at %d." % count)
		await _relocate(Vector2(10434, 546))
	await _send_escape()
	_press_button("Main Menu")
	_check(game.mode == FogTrail.Mode.MAIN and not is_instance_valid(game.level), "Main Menu discards the current attempt.")
	print("PASS: menus, actual collisions, three repeat deaths, locked counts, pause and restart.")

func _test_touch() -> void:
	game.use_touch = true
	_press_button("Play")
	await _frames(8)
	var player: Hiker = game.level.player
	_check(game.touch.visible, "Touch controls appear in mobile mode.")
	var origin: Vector2 = player.position
	_send_touch(0, &"right", true)
	await _frames(10)
	_send_touch(1, &"jump", true)
	await _frames(10)
	_check(player.position.x > origin.x + 25 and player.position.y < origin.y - 35,
		"Simultaneous move-right and jump contacts actually move the hiker.")
	_send_touch(1, &"jump", false)
	await _frames(2)
	_check(player.touch_axis == 1.0, "Releasing jump does not cancel movement.")
	_send_touch(0, &"right", false)
	await _frames(2)
	_check(player.touch_axis == 0.0, "Releasing direction clears movement.")
	await _frames(37)
	_send_touch(0, &"left", true)
	_send_touch(1, &"jump", true)
	await _frames(3)
	_send_touch(0, &"left", false)
	_check(player.touch_axis == 0.0, "Releasing direction first clears axis while jump is held.")
	_send_touch(1, &"jump", false)
	_send_touch(4, &"right", true)
	var pause_point: Vector2 = _find_button(game.hud, "Pause").get_global_rect().get_center()
	_push_touch(5, pause_point, true)
	_push_touch(5, pause_point, false)
	_check(game.mode == FogTrail.Mode.PAUSED and player.touch_axis == 0.0 and not game.touch.visible,
		"A separate finger can pause while holding a direction. Pause clears input.")
	game.resume_game()
	_send_touch(4, &"right", false)
	_check(player.touch_axis == 0.0 and game.touch.visible, "Resume ignores a previously held finger.")
	_send_touch(7, &"left", true)
	_check(player.touch_axis == -1.0, "Touch after resuming is accepted.")
	var canceled := InputEventScreenTouch.new()
	canceled.index = 7
	canceled.position = game.touch.center_for(&"left")
	canceled.canceled = true
	root.push_input(canceled, true)
	_check(player.touch_axis == 0.0, "Operating system touch cancellation clears movement.")
	game.go_to_menu()
	game.use_touch = false
	print("PASS: simulated independent fingers, both release orders, cancel and pause/resume.")

func _test_two_playthroughs() -> void:
	_press_button("Play")
	await _frames(10)
	_watch_level()
	if not await _cross_trail_to_hollow():
		return
	if not await _late_route(false):
		return
	_check(game.mode == FogTrail.Mode.PLAYING and "1 more lantern" in feedback, "An actual arrival short of a lantern stays locked.")
	if not await _backtrack_to_hollow():
		return
	_check(game.level.progress.collected_count() == 3, "The missed lantern can be retrieved by backtracking from the shelter.")
	if not await _late_route(true):
		return
	if not _check(game.mode == FogTrail.Mode.COMPLETE and wins == 1, "First full playthrough reaches Level Complete once."):
		return
	var finished_at: Vector2 = game.level.player.position
	await _frames(10)
	_check(game.level.player.position == finished_at, "Character stops moving after completion.")
	print("PASS: full playthrough with locked arrival, physical backtracking and shelter completion.")

	_press_button("Play Again")
	await _frames(10)
	_watch_level()
	_assert_reset("Play Again")
	if not await _cross_trail_to_hollow():
		return
	if not await _enter_hollow():
		return
	_check(game.level.progress.collected_count() == 3, "Lower route collects the final lantern before reaching the shelter.")
	if not await _late_route(true):
		return
	_check(game.mode == FogTrail.Mode.COMPLETE and wins == 2, "Second full playthrough also completes exactly once.")
	print("PASS: Play Again resets the level and a second continuous playthrough completes.")

func _test_all_lanterns_reachable_after_shelter() -> void:
	_press_button("Play Again")
	await _frames(10)
	_watch_level()
	if not await _cross_trail_to_hollow(true) or not await _late_route(false):
		return
	if not _check(game.level.progress.collected_count() == 0 and "3 more lanterns" in feedback,
			"The shelter can be reached with no lanterns and stays locked."):
		return
	if not await _backtrack_shelter_to_bank() or not await _backtrack_to_crossing():
		return
	_check(game.level.progress.collected_count() == 1, "The first lantern is reachable from a locked shelter arrival.")
	if not await _cross_trail_to_hollow(false, true) or not await _enter_hollow() or not await _late_route(true):
		return
	_check(game.mode == FogTrail.Mode.COMPLETE and wins == 3, "After backtracking past the ridge, all lanterns can be collected and the trail completed.")
	print("PASS: physically reached the shelter at 0/3, backtracked to the first crossing and recovered all three lanterns.")

func _cross_trail_to_hollow(skip_lanterns: bool = false, from_crossing: bool = false) -> bool:
	var first_crossing: Array[Array] = [
		[615, false], [759, true], [814, false], [956, true],
		[1088, false], [1221, true], [1295, false], [1448, true]
	]
	if not from_crossing:
		first_crossing.append_array([[1518, false], [1708, true]] if skip_lanterns else [[1600, false]])
		if not await _run_route(first_crossing, "First crossing"):
			return false
	if not await _run_route([
		[1776, false], [1919, true], [2265, false], [2409, true],
		[2495, false], [2641, true], [2747, false], [2898, true],
		[3166, false], [3329, true], [3656, false], [3806, true],
		[4030, false], [4112, false]
	], "Approach to Pine Ridge"):
		return false
	var ridge: Array[Array] = [
		[4190, true], [4250, false], [4392, true], [4528, false],
		[4672, true], [4825, false], [4977, false]
	]
	if skip_lanterns:
		ridge = [[4315, false], [4471, true]]
	if not await _run_route(ridge, "Pine Ridge"):
		return false
	var arrived: bool = await _run_route([
		[5002, false], [5147, true], [5238, false], [5382, true],
		[5556, false], [5709, true], [5813, false], [5931, true],
		[6035, false], [6190, true], [6400, false]
	], "Pine Ridge through Foggy Hollow")
	if arrived:
		_check(game.level.progress.collected_count() == (0 if skip_lanterns else 2), "Route uses the intended lantern pickups.")
	return arrived

func _enter_hollow() -> bool:
	return await _run_route([[6463, false], [6530, false], [6709, false], [6771, true]], "Foggy Hollow side route")

func _late_route(from_lower: bool) -> bool:
	if from_lower:
		if not await _run_route([[6767, false], [6860, true]], "Lower exit"):
			return false
	else:
		if not await _run_route([[6556, true], [6656, false], [6847, true]], "Upper bridge"):
			return false
	return await _run_route([
		[7161, false], [7314, true], [7622, false], [7776, true],
		[7898, false], [8055, true], [8230, false], [8390, true], [8575, false],
		[8730, true], [9116, false], [9266, true], [9523, false], [9691, true],
		[9810, false], [9945, true], [10057, false], [10219, true], [10520, false]
	], "Lookout to shelter")

func _backtrack_to_hollow() -> bool:
	if not await _backtrack_shelter_to_bank():
		return false
	return await _run_route([[6782, false], [6530, false], [6709, false], [6771, true]],
		"Far Bank to the Hollow lantern")

func _backtrack_shelter_to_bank() -> bool:
	return await _run_route([
		[10210, false], [10049, true], [9955, false], [9810, true], [9684, false],
		[9517, true], [9258, false], [9112, true], [8725, false], [8573, true],
		[8384, false], [8227, true], [8047, false], [7890, true], [7769, false],
		[7616, true], [7311, false], [7156, true], [6851, false]
	], "Shelter backtrack to Far Bank")

func _backtrack_to_crossing() -> bool:
	return await _run_route([
		[6832, false], [6658, true], [6548, false], [6389, true],
		[6190, false], [6031, true], [5943, false], [5805, true], [5704, false],
		[5549, true], [5380, false], [5237, true], [5143, false], [4993, true],
		[4467, false], [4317, true], [3801, false], [3650, true], [3324, false],
		[3165, true], [2890, false], [2746, true], [2631, false], [2495, true],
		[2403, false], [2262, true], [1918, false], [1771, true], [1600, false]
	], "Far Bank backtrack to the first crossing lantern")

func _run_route(route: Array[Array], name: String) -> bool:
	for step: Array in route:
		var target: float = float(step[0])
		var jump: bool = bool(step[1])
		if not await _move_to(target, jump):
			var player: Hiker = game.level.player
			_check(false, "%s could not reach x=%d (jump=%s) from route position %s, velocity %s, floor=%s." %
				[name, int(target), jump, player.position, player.velocity, player.is_on_floor()])
			return false
	return true

func _move_to(target: float, jump: bool) -> bool:
	var player: Hiker = game.level.player
	var direction: float = signf(target - player.position.x)
	var action: StringName = &"move_right" if direction > 0.0 else &"move_left"
	var initial_respawns: int = respawns
	Input.action_press(action)
	if jump:
		Input.action_press(&"jump")
	await _frames(2)
	Input.action_release(&"jump")
	for tick in range(190):
		if game.mode == FogTrail.Mode.COMPLETE:
			_release_inputs()
			return true
		if (player.position.x - target) * direction >= -2.0:
			Input.action_release(action)
			for landing_tick in range(55):
				await _frames(1)
				if game.mode == FogTrail.Mode.COMPLETE:
					return true
				if absf(player.position.x - target) > 55.0:
					return false
				if player.is_on_floor():
					return true
			return false
		if respawns != initial_respawns:
			break
		await _frames(1)
	_release_inputs()
	return false

func _assert_reset(label: String) -> void:
	_check(game.mode == FogTrail.Mode.PLAYING, "%s starts the level." % label)
	_check(game.level.progress.collected_count() == 0 and game.level.progress.total() == 3, "%s resets all lanterns." % label)
	_check(game.level.progress.respawn_point == game.level.start.global_position, "%s resets the checkpoint." % label)
	_check(game.level.player.position.distance_to(game.level.start.global_position) < 5.0, "%s resets the hiker position." % label)

func _watch_level() -> void:
	feedback = ""
	game.level.feedback.connect(func(message: String) -> void: feedback = message)
	game.level.completed.connect(func() -> void: wins += 1)
	game.level.respawned.connect(func() -> void: respawns += 1)

func _send_escape() -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.physical_keycode = KEY_ESCAPE
	root.push_input(event, true)
	await _frames(1)

func _send_touch(index: int, action: StringName, pressed: bool) -> void:
	_push_touch(index, game.touch.center_for(action), pressed)

func _push_touch(index: int, point: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = point
	event.pressed = pressed
	root.push_input(event, true)

func _find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption and node.is_visible_in_tree():
		return node
	for child in node.get_children():
		var found := _find_button(child, caption)
		if found != null:
			return found
	return null

func _press_button(caption: String) -> void:
	var button := _find_button(game.hud, caption)
	if _check(button != null, "Visible button %s is present." % caption):
		button.pressed.emit()

func _relocate(point: Vector2) -> void:
	game.level.player.place_at(point)
	await _frames(8)

func _release_inputs() -> void:
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"jump")

func _frames(count: int) -> void:
	for index in range(count):
		await physics_frame
