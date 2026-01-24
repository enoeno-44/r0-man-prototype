# AutoLoad: DebugManager
extends CanvasLayer

signal debug_mode_toggled(enabled: bool)

var debug_enabled: bool = false
var show_fps: bool = true
var show_position: bool = true
var god_mode: bool = false

var player_speed_multiplier: float = 1.0
var time_scale_multiplier: float = 1.0

@onready var debug_panel: Panel
@onready var fps_label: Label
@onready var position_label: Label
@onready var day_label: Label
@onready var quest_label: Label
@onready var time_label: Label

var debug_menu: Panel
var is_menu_open: bool = false

# Hotkeys
const TOGGLE_DEBUG_KEY = KEY_F1
const TOGGLE_MENU_KEY = KEY_F2
const NEXT_DAY_KEY = KEY_F3
const SKIP_DIALOGUE_KEY = KEY_F4
const SKIP_QTE_KEY = KEY_F5
const SPEED_UP_KEY = KEY_F6
const SLOW_DOWN_KEY = KEY_F7
const RESET_SPEED_KEY = KEY_F8
const COMPLETE_ALL_QUESTS_KEY = KEY_F9
const GOD_MODE_KEY = KEY_F10

func _ready():
	layer = 999
	_create_debug_ui()
	_create_debug_menu()
	_update_visibility()

func _process(_delta):
	if not debug_enabled:
		return
	_update_debug_info()

func _input(event):
	if not event is InputEventKey or not event.pressed:
		return
	
	match event.keycode:
		TOGGLE_DEBUG_KEY: toggle_debug_mode()
		TOGGLE_MENU_KEY: if debug_enabled: toggle_debug_menu()
		NEXT_DAY_KEY: if debug_enabled: _debug_next_day()
		SKIP_DIALOGUE_KEY: if debug_enabled: _debug_skip_dialogue()
		SKIP_QTE_KEY: if debug_enabled: _debug_skip_qte()
		SPEED_UP_KEY: if debug_enabled: _debug_speed_up_player()
		SLOW_DOWN_KEY: if debug_enabled: _debug_slow_down_player()
		RESET_SPEED_KEY: if debug_enabled: _debug_reset_player_speed()
		COMPLETE_ALL_QUESTS_KEY: if debug_enabled: _debug_complete_all_quests()
		GOD_MODE_KEY: if debug_enabled: _debug_toggle_god_mode()

func _create_debug_ui():
	debug_panel = Panel.new()
	debug_panel.name = "DebugPanel"
	debug_panel.custom_minimum_size = Vector2(300, 150)
	debug_panel.position = Vector2(10, 10)
	add_child(debug_panel)
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	vbox.custom_minimum_size = Vector2(280, 130)
	debug_panel.add_child(vbox)
	
	var title = Label.new()
	title.text = "=== DEBUG MODE ==="
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color.YELLOW)
	vbox.add_child(title)
	
	fps_label = Label.new()
	fps_label.text = "FPS: 60"
	vbox.add_child(fps_label)
	
	position_label = Label.new()
	position_label.text = "Position: (0, 0)"
	vbox.add_child(position_label)
	
	day_label = Label.new()
	day_label.text = "Day: 1"
	vbox.add_child(day_label)
	
	time_label = Label.new()
	time_label.text = "Time: 06:00"
	vbox.add_child(time_label)
	
	quest_label = Label.new()
	quest_label.text = "Quests: 0/0"
	vbox.add_child(quest_label)
	
	var hint = Label.new()
	hint.text = "F2: Open Menu"
	hint.add_theme_color_override("font_color", Color.GRAY)
	hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(hint)

func _create_debug_menu():
	debug_menu = Panel.new()
	debug_menu.name = "DebugMenu"
	debug_menu.custom_minimum_size = Vector2(500, 600)
	debug_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(debug_menu)
	
	debug_menu.anchor_left = 0.5
	debug_menu.anchor_top = 0.5
	debug_menu.anchor_right = 0.5
	debug_menu.anchor_bottom = 0.5
	debug_menu.offset_left = -250
	debug_menu.offset_top = -300
	debug_menu.offset_right = 250
	debug_menu.offset_bottom = 300
	
	var scroll = ScrollContainer.new()
	scroll.size = Vector2(480, 580)
	scroll.position = Vector2(10, 10)
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_ALWAYS
	debug_menu.add_child(scroll)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 5)
	scroll.add_child(vbox)
	
	var title = Label.new()
	title.text = "DEBUG MENU (F2)"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color.YELLOW)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	_add_separator(vbox)
	_add_header(vbox, "DAY CONTROLS")
	_add_button(vbox, "Next Day (F3)", _debug_next_day)
	_add_button(vbox, "Jump to Day 2", func(): _debug_jump_to_day(2))
	_add_button(vbox, "Jump to Day 3", func(): _debug_jump_to_day(3))
	_add_button(vbox, "Jump to Day 4", func(): _debug_jump_to_day(4))
	_add_button(vbox, "Jump to Day 5", func(): _debug_jump_to_day(5))
	_add_button(vbox, "Jump to Day 6", func(): _debug_jump_to_day(6))
	
	_add_separator(vbox)
	_add_header(vbox, "QUEST CONTROLS")
	_add_button(vbox, "Complete All Quests Today (F9)", _debug_complete_all_quests)
	_add_button(vbox, "Reset All Quests Today", _debug_reset_all_quests)
	_add_button(vbox, "Complete Current Quest", _debug_complete_current_quest)
	
	_add_separator(vbox)
	_add_header(vbox, "DIALOGUE CONTROLS")
	_add_button(vbox, "Skip Dialogue (F4)", _debug_skip_dialogue)
	_add_button(vbox, "Force Close Dialogue", _debug_force_close_dialogue)
	
	_add_separator(vbox)
	_add_header(vbox, "QTE CONTROLS")
	_add_button(vbox, "Skip QTE (F5)", _debug_skip_qte)
	_add_button(vbox, "Auto-Complete QTE", _debug_auto_complete_qte)
	_add_toggle(vbox, "God Mode (F10): ", god_mode, _debug_toggle_god_mode)
	
	_add_separator(vbox)
	_add_header(vbox, "PLAYER CONTROLS")
	_add_button(vbox, "Speed x2 (F6)", _debug_speed_up_player)
	_add_button(vbox, "Speed x0.5 (F7)", _debug_slow_down_player)
	_add_button(vbox, "Reset Speed (F8)", _debug_reset_player_speed)
	_add_button(vbox, "Teleport to Charger", _debug_teleport_to_charger)
	
	_add_separator(vbox)
	_add_header(vbox, "TIME CONTROLS")
	_add_button(vbox, "Set Time to 6:00", func(): _debug_set_time(6, 0))
	_add_button(vbox, "Set Time to 12:00", func(): _debug_set_time(12, 0))
	_add_button(vbox, "Set Time to 18:00", func(): _debug_set_time(18, 0))
	_add_button(vbox, "Speed Up Time x2", func(): _debug_time_scale(2.0))
	_add_button(vbox, "Normal Time Speed", func(): _debug_time_scale(1.0))
	_add_button(vbox, "Slow Down Time x0.5", func(): _debug_time_scale(0.5))
	
	_add_separator(vbox)
	_add_header(vbox, "SYSTEM CONTROLS")
	_add_toggle(vbox, "Show FPS: ", show_fps, func(val): show_fps = val)
	_add_toggle(vbox, "Show Position: ", show_position, func(val): show_position = val)
	_add_button(vbox, "Reload Scene", _debug_reload_scene)
	_add_button(vbox, "Close Menu (F2)", toggle_debug_menu)
	
	debug_menu.hide()

func _add_header(parent: VBoxContainer, text: String):
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.CYAN)
	parent.add_child(label)

func _add_separator(parent: VBoxContainer):
	parent.add_child(HSeparator.new())

func _add_button(parent: VBoxContainer, text: String, callback: Callable) -> Button:
	var btn = Button.new()
	btn.text = text
	btn.pressed.connect(callback)
	parent.add_child(btn)
	return btn

func _add_toggle(parent: VBoxContainer, label_text: String, initial_value: bool, callback: Callable) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	parent.add_child(hbox)
	
	var label = Label.new()
	label.text = label_text
	hbox.add_child(label)
	
	var checkbox = CheckBox.new()
	checkbox.button_pressed = initial_value
	checkbox.toggled.connect(callback)
	hbox.add_child(checkbox)
	
	return hbox

func _update_debug_info():
	if show_fps:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
		fps_label.show()
	else:
		fps_label.hide()
	
	if show_position:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			position_label.text = "Position: (%.0f, %.0f)" % [player.global_position.x, player.global_position.y]
		position_label.show()
	else:
		position_label.hide()
	
	if has_node("/root/DayManager"):
		var date = DayManager.get_current_date_text()
		day_label.text = "Day: %d (%s)" % [DayManager.get_current_day(), date]
	
	if has_node("/root/TimeManager"):
		time_label.text = "Time: %02d:%02d" % [TimeManager.hour, TimeManager.minute]
	
	if has_node("/root/DayManager"):
		var completed = DayManager.get_completed_count()
		var total = DayManager.get_total_quests_today()
		quest_label.text = "Quests: %d/%d" % [completed, total]

func _update_visibility():
	debug_panel.visible = debug_enabled
	if not debug_enabled:
		debug_menu.hide()
		is_menu_open = false

func toggle_debug_mode():
	debug_enabled = not debug_enabled
	_update_visibility()
	debug_mode_toggled.emit(debug_enabled)

func toggle_debug_menu():
	is_menu_open = not is_menu_open
	debug_menu.visible = is_menu_open

func _debug_next_day():
	if has_node("/root/DayManager"):
		_debug_complete_all_quests()
		await get_tree().create_timer(0.3).timeout
		DayManager.advance_to_next_day()

func _debug_jump_to_day(day: int):
	if has_node("/root/DayManager"):
		while DayManager.get_current_day() < day:
			_debug_complete_all_quests()
			await get_tree().create_timer(0.1).timeout
			DayManager.advance_to_next_day()
			await get_tree().create_timer(0.5).timeout

func _debug_complete_all_quests():
	if not has_node("/root/QuestManager") or not has_node("/root/DayManager"):
		return
	
	var current_day = DayManager.get_current_day()
	var quests = QuestManager.get_quests_for_day(current_day, true)
	
	for quest_data in quests:
		if not quest_data.done:
			QuestManager.complete_quest(quest_data.id)

func _debug_reset_all_quests():
	if not has_node("/root/QuestManager") or not has_node("/root/DayManager"):
		return
	
	var current_day = DayManager.get_current_day()
	var quests = QuestManager.get_quests_for_day(current_day, true)
	
	for quest_data in quests:
		if quest_data.id in QuestManager.quests:
			QuestManager.quests[quest_data.id].done = false

func _debug_complete_current_quest():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var quest_areas = get_tree().get_nodes_in_group("quest_area")
	var nearest_quest = null
	var nearest_distance = INF
	
	for area in quest_areas:
		var distance = player.global_position.distance_to(area.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_quest = area
	
	if nearest_quest and nearest_quest.has_method("get_quest_id"):
		var quest_id = nearest_quest.get_quest_id() if nearest_quest.has_method("get_quest_id") else nearest_quest.quest_id
		QuestManager.complete_quest(quest_id)

func _debug_skip_dialogue():
	if has_node("/root/SystemDialogueManager"):
		SystemDialogueManager.hide_dialogue()
	if has_node("/root/DialogueManager"):
		DialogueManager.dialogue_ended.emit()

func _debug_force_close_dialogue():
	if has_node("/root/SystemDialogueManager"):
		SystemDialogueManager.hide_dialogue()

func _debug_skip_qte():
	if has_node("/root/QTEManager"):
		if QTEManager.is_active():
			QTEManager.force_end_qte()

func _debug_auto_complete_qte():
	if not has_node("/root/QTEManager"):
		return
	
	if QTEManager.is_active() and QTEManager.current_object_id != "":
		var quest_id = QTEManager.current_object_id
		var progress = QTEManager.get_progress(quest_id)
		var remaining = progress.required - progress.current
		
		for i in range(remaining):
			QTEManager.qte_progress[quest_id]["current"] += 1
		
		QTEManager.force_end_qte()
		QTEManager.qte_fully_completed.emit(quest_id)

func _debug_toggle_god_mode():
	god_mode = not god_mode
	if god_mode and has_node("/root/QTEManager") and QTEManager.is_active():
		_debug_auto_complete_qte()

func _debug_speed_up_player():
	player_speed_multiplier *= 2.0
	_apply_player_speed()

func _debug_slow_down_player():
	player_speed_multiplier *= 0.5
	_apply_player_speed()

func _debug_reset_player_speed():
	player_speed_multiplier = 1.0
	_apply_player_speed()

func _apply_player_speed():
	var player = get_tree().get_first_node_in_group("player")
	if player and "speed" in player:
		var base_speed = 120.0
		player.speed = base_speed * player_speed_multiplier

func _debug_teleport_to_charger():
	var player = get_tree().get_first_node_in_group("player")
	var charger = get_tree().get_first_node_in_group("charger")
	if player and charger:
		player.global_position = charger.global_position

func _debug_set_time(hour: int, minute: int):
	if has_node("/root/TimeManager"):
		TimeManager.hour = hour
		TimeManager.minute = minute

func _debug_time_scale(scale: float):
	time_scale_multiplier = scale
	if has_node("/root/TimeManager"):
		TimeManager.time_scale = 1.2 * time_scale_multiplier

func _debug_reload_scene():
	get_tree().reload_current_scene()
