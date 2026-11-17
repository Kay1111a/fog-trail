class_name TrailCampaign
extends RefCounted
## Records completed stages independently of the current attempt.

const SAVE_PATH := "user://trail_campaign.cfg"
const SECTION := "campaign"
const CLEAR_KEY := "cleared_count"

var cleared_count: int = 0
var save_error: Error = OK
var _saved_count: int = 0
var _save_path: String

func _init(save_path: String = SAVE_PATH) -> void:
	_save_path = save_path

func load_progress() -> void:
	cleared_count = _read_count()
	_saved_count = cleared_count
	save_error = OK

func next_available() -> int:
	return mini(cleared_count + 1, TrailStages.COUNT)

func can_start(stage: int) -> bool:
	return stage >= 1 and stage <= next_available()

func record_clear(stage: int) -> void:
	if stage == cleared_count + 1 and can_start(stage):
		cleared_count = stage
	if _save_path.is_empty() or cleared_count == _saved_count:
		return
	# Preserve progress already saved by another open game.
	cleared_count = maxi(cleared_count, _read_count())
	var config := ConfigFile.new()
	config.set_value(SECTION, CLEAR_KEY, cleared_count)
	var temporary := "%s.%d.tmp" % [_save_path, OS.get_process_id()]
	save_error = config.save(temporary)
	if save_error == OK:
		save_error = DirAccess.rename_absolute(temporary, _save_path)
	if save_error == OK:
		_saved_count = cleared_count
	elif FileAccess.file_exists(temporary):
		DirAccess.remove_absolute(temporary)

func _read_count() -> int:
	if _save_path.is_empty() or not FileAccess.file_exists(_save_path):
		return 0
	var config := ConfigFile.new()
	if config.load(_save_path) != OK:
		return 0
	var count: Variant = config.get_value(SECTION, CLEAR_KEY, 0)
	if not count is int or count < 0 or count > TrailStages.COUNT:
		return 0
	return int(count)
