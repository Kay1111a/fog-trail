class_name TrailHUD
extends Control

signal play_requested
signal controls_requested
signal menu_requested
signal pause_requested
signal resume_requested
signal restart_requested

const BODY := preload("res://assets/fonts/Inter-Variable.ttf")
const DISPLAY := preload("res://assets/fonts/InstrumentSerif-Regular.ttf")
const INK := Color("#ecdfc8")
const SOFT := Color("#a9bfb5")
const GOLD := Color("#efc082")
const WALL := Color(0.059, 0.129, 0.153, 0.94)

var _sheet: Control
var _hud: Control
var _number: Label
var _pips: HBoxContainer
var _toast: PanelContainer
var _toast_text: Label
var _message_timer: Timer

func _ready() -> void:
	_build_hud()

func _build_hud() -> void:
	_hud = Control.new()
	_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hud)
	_hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var chip := PanelContainer.new()
	chip.add_theme_stylebox_override("panel", _style(WALL, Color("#69837a"), 14, 15, 10))
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.position = Vector2(27, 24)
	_hud.add_child(chip)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	_number = _label("Lanterns 0/3", 19, BODY, INK)
	row.add_child(_number)
	_pips = HBoxContainer.new()
	_pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pips.add_theme_constant_override("separation", 6)
	row.add_child(_pips)

	var pause := _button("Pause", false, 112)
	_hud.add_child(pause)
	pause.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause.offset_left = -143
	pause.offset_right = -28
	pause.offset_top = 24
	pause.offset_bottom = 74
	pause.focus_mode = Control.FOCUS_NONE
	pause.pressed.connect(func() -> void: pause_requested.emit())

	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", _style(WALL, Color("#77958b"), 11, 17, 10))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud.add_child(_toast)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast.offset_left = -234
	_toast.offset_right = 234
	_toast.offset_top = -90
	_toast.offset_bottom = -44
	_toast_text = _label("", 17, BODY, INK)
	_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_child(_toast_text)
	_message_timer = Timer.new()
	_message_timer.one_shot = true
	_message_timer.timeout.connect(_toast.hide)
	add_child(_message_timer)
	_toast.hide()

func _label(value: String, font_size: int, font: Font, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _style(fill: Color, stroke: Color, radius: int, side: int, vertical: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = stroke
	box.set_border_width_all(1)
	box.set_corner_radius_all(radius)
	box.content_margin_left = side
	box.content_margin_right = side
	box.content_margin_top = vertical
	box.content_margin_bottom = vertical
	return box

func _button(title: String, primary: bool, width: int = 254) -> Button:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(width, 53)
	button.add_theme_font_override("font", BODY)
	button.add_theme_font_size_override("font_size", 19)
	var normal := GOLD if primary else Color("#263d43")
	var hover := Color("#ffdb9c") if primary else Color("#39565b")
	var press := Color("#dfaa70") if primary else Color("#1c3036")
	var text_tint := Color("#192830") if primary else INK
	button.add_theme_color_override("font_color", text_tint)
	button.add_theme_color_override("font_focus_color", text_tint)
	button.add_theme_color_override("font_hover_color", text_tint)
	button.add_theme_color_override("font_pressed_color", text_tint)
	button.add_theme_stylebox_override("normal", _style(normal, Color("#8c9d89"), 10, 18, 10))
	button.add_theme_stylebox_override("hover", _style(hover, Color("#a0bfad"), 10, 18, 10))
	button.add_theme_stylebox_override("pressed", _style(press, Color("#a0bfad"), 10, 18, 10))
	var focus := _style(Color.TRANSPARENT, Color("#f8ebce"), 10, 0, 0)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override("focus", focus)
	return button

func _add_button(row: BoxContainer, name_text: String, primary: bool, action: Callable) -> Button:
	var button := _button(name_text, primary)
	row.add_child(button)
	button.pressed.connect(action)
	return button

func _clear_sheet() -> void:
	if is_instance_valid(_sheet):
		remove_child(_sheet)
		_sheet.queue_free()
		_sheet = null

func _new_sheet() -> Control:
	_clear_sheet()
	_sheet = Control.new()
	add_child(_sheet)
	_sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	return _sheet

func _box(root: Control, anchor: int, rectangle: Rect2) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _style(WALL, Color("#5a7b73"), 18, 35, 28))
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(anchor)
	panel.offset_left = rectangle.position.x
	panel.offset_top = rectangle.position.y
	panel.offset_right = rectangle.end.x
	panel.offset_bottom = rectangle.end.y
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	return column

func _fade_left(parent: Control) -> void:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0, 0.45, 0.84, 1])
	gradient.colors = PackedColorArray([Color(0.039, 0.082, 0.112, 0.96),
		Color(0.05, 0.105, 0.13, 0.76), Color(0.055, 0.115, 0.14, 0.12), Color.TRANSPARENT])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	var bg := TextureRect.new()
	bg.texture = texture
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _dim(parent: Control) -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.026, 0.057, 0.076, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func show_main_menu() -> void:
	_hud.hide()
	var root := _new_sheet()
	_fade_left(root)
	var stack := VBoxContainer.new()
	stack.position = Vector2(104, 176)
	stack.add_theme_constant_override("separation", 18)
	root.add_child(stack)

	var title := _label("Fog Trail", 142, DISPLAY, INK)
	stack.add_child(title)
	stack.add_child(_label("Collect three lanterns to open\nthe trail shelter.", 24, BODY, Color("#cfddd1")))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 13)
	stack.add_child(actions)
	var play := _button("Play", true, 146)
	var controls := _button("Controls", false, 146)
	actions.add_child(play)
	actions.add_child(controls)
	play.pressed.connect(func() -> void: play_requested.emit())
	controls.pressed.connect(func() -> void: controls_requested.emit())
	play.grab_focus.call_deferred()

func show_controls() -> void:
	_hud.hide()
	var sheet := _new_sheet()
	_dim(sheet)
	var column := _box(sheet, Control.PRESET_CENTER, Rect2(-260, -205, 520, 410))
	column.add_child(_label("Controls", 63, DISPLAY, INK))
	column.add_child(_label("Move   ·   A / D or Left / Right\nJump   ·   Space\nPause   ·   Esc", 21, BODY, INK))
	column.add_child(_label("On Android, use the arrows and jump button.\nYou can move and jump together.", 18, BODY, SOFT))
	var back := _add_button(column, "Back", true, func() -> void: menu_requested.emit())
	back.grab_focus.call_deferred()

func begin_stage(total: int, mobile: bool) -> void:
	show_stage()
	set_lanterns(0, total)
	show_feedback("Use the arrows to move and jump." if mobile else "A / D or arrows to move · Space to jump", 5.0)

func show_stage() -> void:
	_clear_sheet()
	_hud.show()

func set_lanterns(collected: int, total: int) -> void:
	_number.text = "Lanterns %d/%d" % [collected, total]
	for child in _pips.get_children():
		_pips.remove_child(child)
		child.queue_free()
	for index in range(total):
		var light := Panel.new()
		light.custom_minimum_size = Vector2(12, 18)
		light.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		light.mouse_filter = Control.MOUSE_FILTER_IGNORE
		light.add_theme_stylebox_override("panel", _style(GOLD if index < collected else Color("#334b4a"),
			Color("#9caa8d"), 4, 0, 0))
		_pips.add_child(light)

func show_feedback(value: String, seconds: float = 3.6) -> void:
	_toast_text.text = value
	_toast.show()
	_message_timer.start(seconds)

func show_pause() -> void:
	_hud.hide()
	var root := _new_sheet()
	_dim(root)
	var column := _box(root, Control.PRESET_CENTER, Rect2(-223, -185, 446, 370))
	column.add_child(_label("Paused", 74, DISPLAY, INK))
	var resume := _add_button(column, "Resume", true, func() -> void: resume_requested.emit())
	_add_button(column, "Restart Level", false, func() -> void: restart_requested.emit())
	_add_button(column, "Main Menu", false, func() -> void: menu_requested.emit())
	resume.grab_focus.call_deferred()

func show_complete() -> void:
	_hud.hide()
	var root := _new_sheet()
	_dim(root)
	var column := _box(root, Control.PRESET_CENTER, Rect2(-253, -162, 506, 324))
	column.add_child(_label("Level Complete", 68, DISPLAY, INK))
	column.add_child(_label("You made it to the trail shelter.", 19, BODY, SOFT))
	var replay := _add_button(column, "Play Again", true, func() -> void: play_requested.emit())
	_add_button(column, "Main Menu", false, func() -> void: menu_requested.emit())
	replay.grab_focus.call_deferred()
