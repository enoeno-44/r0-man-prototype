# pause_menu.gd
# แนบกับ PauseMenu Node (ควรเป็น CanvasLayer หรือ Control)
extends CanvasLayer

@onready var panel = $ColorRect/CenterContainer/Panel
@onready var title_label = $ColorRect/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var resume_button = $ColorRect/CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var settings_button = $ColorRect/CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var quit_to_menu_button = $ColorRect/CenterContainer/Panel/VBoxContainer/QuitToMenuButton

# Settings Panel
@onready var settings_panel = $ColorRect/SettingsPanel

@export var main_menu_path: String = "res://main_menu.tscn"
const CONFIRMATION_DIALOG = preload("res://Scenes/confirmation_dialog.tscn")

var is_paused: bool = false

func _ready():
	# ซ่อนเมนูตอนเริ่มเกม
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # ให้ทำงานได้แม้เกมหยุด
	
	_setup_buttons()
	
	# ซ่อน Settings Panel ตอนเริ่มต้น
	if settings_panel:
		settings_panel.hide()

func _setup_buttons():
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)
	
	# เชื่อม Back Button ของ Settings Panel
	if settings_panel and settings_panel.has_node("VBoxContainer/BackButton"):
		var back_button = settings_panel.get_node("VBoxContainer/BackButton")
		back_button.pressed.connect(_on_settings_back_pressed)

func _input(event):
	# กด ESC หรือ Start เพื่อเปิด/ปิด Pause Menu
	if event.is_action_pressed("ui_cancel"):  # ESC key
		# ถ้า Settings Panel เปิดอยู่ ให้ปิด Settings ก่อน
		if settings_panel and settings_panel.visible:
			_on_settings_back_pressed()
			get_viewport().set_input_as_handled()
			return
		
		# ถ้าไม่ ให้ทำงานปกติ
		if is_paused:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func pause_game():
	is_paused = true
	get_tree().paused = true
	show()
	
	# แสดงเมนูหลัก ซ่อน Settings
	panel.show()
	if settings_panel:
		settings_panel.hide()
	
	# Focus ที่ปุ่ม Resume
	resume_button.grab_focus()
	
	print("[PauseMenu] เกมหยุดชั่วคราว")

func resume_game():
	is_paused = false
	get_tree().paused = false
	hide()
	
	print("[PauseMenu] เกมดำเนินต่อ")

func _on_resume_pressed():
	AudioManager.play_sfx("ui_click")
	resume_game()

func _on_settings_pressed():
	"""เปิด Settings Panel"""
	AudioManager.play_sfx("ui_click")
	if settings_panel:
		panel.hide()
		settings_panel.show()
		# Focus ปุ่ม Back
		if settings_panel.has_node("VBoxContainer/BackButton"):
			settings_panel.get_node("VBoxContainer/BackButton").grab_focus()
	print("[PauseMenu] เปิด Settings Panel")

func _on_settings_back_pressed():
	"""ปิด Settings Panel กลับมา Pause Menu"""
	AudioManager.play_sfx("ui_click")
	if settings_panel:
		settings_panel.hide()
		panel.show()
		# Focus ปุ่ม Settings
		settings_button.grab_focus()
	print("[PauseMenu] ปิด Settings Panel")

func _on_quit_to_menu_pressed():
	# แสดง Confirmation Dialog ก่อนออกไปเมนูหลัก
	_show_quit_confirmation()

func _show_quit_confirmation():
	var dialog = CONFIRMATION_DIALOG.instantiate()
	add_child(dialog)
	
	dialog.setup(
		"คุณต้องการบันทึกเกมก่อนกลับ\nไปเมนูหลักหรือไม่?",
		"บันทึกและออก",
		"ยกเลิก",
		"ออกโดยไม่บันทึก"  # ปุ่มที่ 3
	)
	
	dialog.confirmed.connect(func():
		_quit_with_save()
	)
	
	dialog.cancelled.connect(func():
		pass  # ไม่ทำอะไร
	)
	
	dialog.extra_action.connect(func(action):
		_quit_without_save()
	)

func _quit_with_save():
	# บันทึกเกมก่อนออก
	if has_node("/root/SaveManager"):
		SaveManager.save_game()
	
	_return_to_main_menu()

func _quit_without_save():
	# ออกเลยโดยไม่บันทึก
	_return_to_main_menu()

func _return_to_main_menu():
	# ยกเลิก pause ก่อนเปลี่ยน scene
	get_tree().paused = false
	AudioManager.stop_bgm()
	
	# ปิดการทำงาน Managers (ให้เมนูหลักจัดการเอง)
	if has_node("/root/TransitionManager"):
		TransitionManager.transition_to_scene(main_menu_path)
	else:
		get_tree().change_scene_to_file(main_menu_path)
	
	print("[PauseMenu] กลับไปเมนูหลัก")
