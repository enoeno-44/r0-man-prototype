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
@export var day_selection_scene: PackedScene

const CONFIRMATION_DIALOG = preload("res://Scenes/confirmation_dialog.tscn")

var day_selection_instance = null

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
	
	# *** FIX: ตรวจสอบว่าเกมจบแล้วหรือยัง ***
	var game_completed = SaveManager.is_game_completed()
	
	# ปิดปุ่ม Continue ถ้าไม่มีเซฟ หรือ เกมจบแล้ว
	continue_button.disabled = not has_save or game_completed
	
	# ปิดปุ่ม Load Day ถ้าไม่มีเซฟ
	load_day_button.disabled = not has_save
	
	# *** เพิ่ม tooltip เพื่ออธิบาย ***
	if game_completed:
		continue_button.tooltip_text = "เกมจบแล้ว - กรุณาใช้ 'โหลดวัน' หรือเริ่มเกมใหม่"
	else:
		continue_button.tooltip_text = ""

func _update_save_info():
	if SaveManager.has_save_file():
		var info = SaveManager.get_save_info()
		var max_day = info.get("max_day_reached", info.get("day", 1))
		var game_completed = info.get("game_completed", false)
		
		if game_completed:
			save_info_label.text = "(เกมจบแล้ว)"
		else:
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
	var dialog = CONFIRMATION_DIALOG.instantiate()
	add_child(dialog)
	
	dialog.setup(
		"เริ่มเกมใหม่จะลบข้อมูลเซฟเดิม\nคุณแน่ใจหรือไม่?",
		"ใช่, เริ่มใหม่",
		"ยกเลิก"
	)
	
	dialog.confirmed.connect(func():
		_start_new_game()
	)
	
	dialog.cancelled.connect(func():
		pass  # ไม่ต้องทำอะไร
	)

func _start_new_game():
	SaveManager.delete_save()
	SaveManager.reset_game()
	AudioManager.play_sfx("ui_click")
	_enable_game_managers()
	
	if has_node("/root/TransitionManager"):
		TransitionManager.transition_to_new_game(game_scene_path)
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
	_show_day_selection_menu()

func _show_day_selection_menu():
	if not day_selection_scene:
		_show_error_dialog("ไม่พบ Day Selection Scene!")
		return
	
	# สร้าง instance ของ day selection menu
	day_selection_instance = day_selection_scene.instantiate()
	day_selection_instance.game_scene_path = game_scene_path
	add_child(day_selection_instance)
	
	# ซ่อนเมนูหลัก
	main_vbox.hide()
	
	# เชื่อมต่อ signal
	day_selection_instance.back_pressed.connect(_on_day_selection_back)
	day_selection_instance.day_selected.connect(_on_day_selected)

func _on_day_selection_back():
	# แสดงเมนูหลักกลับมา
	main_vbox.show()
	load_day_button.grab_focus()

func _on_day_selected(day: int):
	print("[MainMenu] เลือกวันที่: %d" % day)
	# เกมจะเปลี่ยน scene ไปแล้วใน day_selection_menu.gd

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
