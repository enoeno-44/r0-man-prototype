# main_menu.gd
extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var new_game_button = $VBoxContainer/PlayButton
@onready var continue_button = $VBoxContainer/HBoxContainer/ContinueButton
@onready var load_day_button = $VBoxContainer/LoadButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var save_info_label = $VBoxContainer/HBoxContainer/SaveInfoLabel
@onready var settings_panel = $SettingsPanel
@onready var main_vbox = $VBoxContainer

@export var game_scene_path: String = "res://world_park.tscn"

func _ready():
	_disable_game_managers()
	_setup_buttons()
	_update_save_info()
	_check_continue_availability()
	
	if settings_panel:
		settings_panel.hide()

func _disable_game_managers():
	# ปิด Managers ทั้งหมดในหน้าเมนู
	if has_node("/root/TransitionManager"):
		TransitionManager.hide()
		TransitionManager.set_process(false)
	
	if has_node("/root/SystemDialogueManager"):
		SystemDialogueManager.hide()
		SystemDialogueManager.set_process(false)
	
	if has_node("/root/TimeManager"):
		TimeManager.set_process(false)

func _setup_buttons():
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	load_day_button.pressed.connect(_on_load_day_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if settings_panel and settings_panel.has_node("VBoxContainer/BackButton"):
		var back_button = settings_panel.get_node("VBoxContainer/BackButton")
		back_button.pressed.connect(_on_settings_back_pressed)

func _check_continue_availability():
	var has_save = SaveManager.has_save_file()
	continue_button.disabled = not has_save
	load_day_button.disabled = not has_save

func _update_save_info():
	if SaveManager.has_save_file():
		var info = SaveManager.get_save_info()
		save_info_label.text = "(เซฟล่าสุด: วันที่ %d)" % [info.day]
		save_info_label.show()
	else:
		save_info_label.text = "ไม่พบข้อมูลเซฟ"
		save_info_label.hide()

func _on_new_game_pressed():
	AudioManager.play_sfx("ui_click")
	if SaveManager.has_save_file():
		_show_confirmation_dialog()
	else:
		_start_new_game()

func _show_confirmation_dialog():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "เริ่มเกมใหม่จะลบข้อมูลเซฟเดิม\nคุณแน่ใจหรือไม่?"
	dialog.ok_button_text = "ใช่, เริ่มใหม่"
	dialog.cancel_button_text = "ยกเลิก"
	dialog.min_size = Vector2(400, 200)
	
	add_child(dialog)
	dialog.popup_centered()
	
	if dialog.has_theme_stylebox("panel", "ConfirmationDialog"):
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
		dialog.add_theme_stylebox_override("panel", style)
	
	dialog.confirmed.connect(func():
		_start_new_game()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)

func _start_new_game():
	SaveManager.delete_save()
	SaveManager.reset_game()
	AudioManager.play_sfx("ui_click")
	_enable_game_managers()
	
	if has_node("/root/TransitionManager"):
		TransitionManager.transition_to_scene(game_scene_path)
	else:
		get_tree().change_scene_to_file(game_scene_path)

func _on_continue_pressed():
	AudioManager.play_sfx("ui_click")
	if SaveManager.load_game():
		_enable_game_managers()
		if has_node("/root/TransitionManager"):
			TransitionManager.transition_to_scene(game_scene_path)
			AudioManager.play_bgm("main_theme", 4.0)
		else:
			get_tree().change_scene_to_file(game_scene_path)
	else:
		_show_error_dialog("ไม่สามารถโหลดเกมได้!")

func _on_load_day_pressed():
	AudioManager.play_sfx("ui_click")
	_show_day_selection_popup()

func _show_day_selection_popup():
	var popup = AcceptDialog.new()
	popup.title = "เลือกวันที่ต้องการโหลด"
	popup.dialog_text = "เลือกวันที่คุณต้องการกลับไปเล่น:"
	
	var vbox = VBoxContainer.new()
	popup.add_child(vbox)
	
	for day in range(1, 7):
		var day_button = Button.new()
		day_button.text = "วันที่ %d - %s (%s)" % [
			day,
			DayManager.day_chapters[day - 1],
			DayManager.day_dates[day - 1]
		]
		day_button.pressed.connect(func():
			_load_specific_day(day)
			popup.queue_free()
		)
		vbox.add_child(day_button)
	
	add_child(popup)
	popup.popup_centered()

func _load_specific_day(day: int):
	# โหลดวันที่เลือกและตั้งค่า quest ก่อนหน้าให้เสร็จสมบูรณ์
	SaveManager.reset_game()
	DayManager.current_day = day
	
	for quest_id in QuestManager.quests.keys():
		var quest = QuestManager.quests[quest_id]
		if quest.day < day:
			quest.done = true
	
	_enable_game_managers()
	
	if has_node("/root/TransitionManager"):
		TransitionManager.transition_to_scene(game_scene_path)
	else:
		get_tree().change_scene_to_file(game_scene_path)

func _on_settings_pressed():
	AudioManager.play_sfx("ui_click")
	if settings_panel:
		main_vbox.hide()
		settings_panel.show()
		if settings_panel.has_node("VBoxContainer/BackButton"):
			settings_panel.get_node("VBoxContainer/BackButton").grab_focus()

func _on_settings_back_pressed():
	AudioManager.play_sfx("ui_click")
	if settings_panel:
		settings_panel.hide()
		main_vbox.show()
		settings_button.grab_focus()

func _show_error_dialog(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _enable_game_managers():
	# เปิด Managers กลับมาใช้งาน
	if has_node("/root/TransitionManager"):
		TransitionManager.show()
		TransitionManager.set_process(true)
	
	if has_node("/root/SystemDialogueManager"):
		SystemDialogueManager.set_process(true)
	
	if has_node("/root/TimeManager"):
		TimeManager.set_process(true)

func _on_quit_pressed():
	get_tree().quit()
