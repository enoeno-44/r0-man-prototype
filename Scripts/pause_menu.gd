# pause_menu.gd
# แนบกับ PauseMenu Node (ควรเป็น CanvasLayer หรือ Control)
extends CanvasLayer

@onready var panel = $ColorRect/CenterContainer/Panel
@onready var title_label = $ColorRect/CenterContainer/Panel/VBoxContainer/TitleLabel
@onready var resume_button = $ColorRect/CenterContainer/Panel/VBoxContainer/ResumeButton
@onready var settings_button = $ColorRect/CenterContainer/Panel/VBoxContainer/SettingsButton
@onready var quit_to_menu_button = $ColorRect/CenterContainer/Panel/VBoxContainer/QuitToMenuButton

@export var main_menu_path: String = "res://main_menu.tscn"

var is_paused: bool = false

func _ready():
	# ซ่อนเมนูตอนเริ่มเกม
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS  # ให้ทำงานได้แม้เกมหยุด
	
	_setup_buttons()

func _setup_buttons():
	resume_button.pressed.connect(_on_resume_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)

func _input(event):
	# กด ESC หรือ Start เพื่อเปิด/ปิด Pause Menu
	if event.is_action_pressed("ui_cancel"):  # ESC key
		if is_paused:
			resume_game()
		else:
			pause_game()
		get_viewport().set_input_as_handled()

func pause_game():
	is_paused = true
	get_tree().paused = true
	show()
	
	# Focus ที่ปุ่ม Resume
	resume_button.grab_focus()
	
	print("[PauseMenu] เกมหยุดชั่วคราว")

func resume_game():
	is_paused = false
	get_tree().paused = false
	hide()
	
	print("[PauseMenu] เกมดำเนินต่อ")

func _on_resume_pressed():
	resume_game()

func _on_settings_pressed():
	# TODO: เปิดเมนู Settings
	print("[PauseMenu] เปิดเมนู Settings (ยังไม่ได้ทำ)")
	# ตัวอย่างการเปิด Settings Panel:
	# $SettingsPanel.show()
	# panel.hide()

func _on_quit_to_menu_pressed():
	# แสดง Confirmation Dialog ก่อนออกไปเมนูหลัก
	_show_quit_confirmation()

func _show_quit_confirmation():
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "คุณต้องการบันทึกเกมก่อนกลับไปเมนูหลักหรือไม่?"
	dialog.ok_button_text = "บันทึกและออก"
	dialog.cancel_button_text = "ยกเลิก"
	
	# เพิ่มปุ่ม "ออกโดยไม่บันทึก"
	dialog.add_button("ออกโดยไม่บันทึก", false, "quit_without_save")
	
	add_child(dialog)
	dialog.popup_centered()
	
	dialog.confirmed.connect(func():
		_quit_with_save()
		dialog.queue_free()
	)
	
	dialog.canceled.connect(func():
		dialog.queue_free()
	)
	
	dialog.custom_action.connect(func(action):
		if action == "quit_without_save":
			_quit_without_save()
		dialog.queue_free()
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
	
	# ปิดการทำงาน Managers (ให้เมนูหลักจัดการเอง)
	if has_node("/root/TransitionManager"):
		TransitionManager.transition_to_scene(main_menu_path)
	else:
		get_tree().change_scene_to_file(main_menu_path)
	
	print("[PauseMenu] กลับไปเมนูหลัก")
