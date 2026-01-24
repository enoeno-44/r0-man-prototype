# day_selection_menu.gd
extends Control

signal day_selected(day: int)
signal back_pressed

@onready var day_list_container = $Background/CenterContainer/MainPanel/MainVBox/DayListScroll/DayListContainer
@onready var back_button = $Background/CenterContainer/MainPanel/MainVBox/ButtonsContainer/BackButton

@export var game_scene_path: String = "res://world_park.tscn"

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	_populate_day_list()
	
	# Focus ปุ่มแรกที่ไม่ถูก disable
	await get_tree().process_frame
	_focus_first_available_button()

func _populate_day_list():
	# ล้างปุ่มเก่าทั้งหมด
	for child in day_list_container.get_children():
		child.queue_free()
	
	# ดึงข้อมูลวันที่ปลดล็อกแล้ว
	var max_day = 1
	if SaveManager.has_save_file():
		var save_info = SaveManager.get_save_info()
		max_day = save_info.get("max_day_reached", 1)
	
	# สร้างปุ่มสำหรับแต่ละวัน (1-6)
	for day in range(1, 7):
		var day_button = _create_day_button(day, max_day)
		day_list_container.add_child(day_button)

func _create_day_button(day: int, max_day: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(0, 60)
	
	# ตั้งค่าข้อความ
	var day_text = "วันที่ %d - %s" % [day, DayManager.day_chapters[day - 1]]
	var date_text = DayManager.day_dates[day - 1]
	button.text = "%s\n%s" % [day_text, date_text]
	
	# ตรวจสอบว่าวันนี้ปลดล็อกหรือยัง
	var is_unlocked = day <= max_day
	
	if not is_unlocked:
		button.disabled = true
		button.text = button.text + " (ล็อก)"
		button.modulate = Color(0.5, 0.5, 0.5)
	else:
		# เชื่อมต่อ signal
		button.pressed.connect(func(): _on_day_button_pressed(day))
		
		# ถ้าเป็นวันปัจจุบัน ให้เน้นสี
		if SaveManager.has_save_file():
			var save_info = SaveManager.get_save_info()
			if day == save_info.get("day", 1):
				button.modulate = Color(1.2, 1.2, 0.8)  # สีเหลืองอ่อน
	
	return button

func _on_day_button_pressed(day: int):
	AudioManager.play_sfx("ui_click")
	_load_day(day)

func _load_day(day: int):
	# โหลดวันที่เลือก
	SaveManager.load_specific_day(day)
	
	# เปิด game managers
	_enable_game_managers()
	
	# เปลี่ยน scene
	if has_node("/root/TransitionManager"):
		TransitionManager.transition_to_scene(game_scene_path)
	else:
		get_tree().change_scene_to_file(game_scene_path)
	
	day_selected.emit(day)

func _on_back_pressed():
	AudioManager.play_sfx("ui_click")
	back_pressed.emit()
	queue_free()

func _focus_first_available_button():
	for child in day_list_container.get_children():
		if child is Button and not child.disabled:
			child.grab_focus()
			break

func _enable_game_managers():
	# เปิด Managers กลับมาใช้งาน
	if has_node("/root/TransitionManager"):
		TransitionManager.show()
		TransitionManager.set_process(true)
	
	if has_node("/root/SystemDialogueManager"):
		SystemDialogueManager.set_process(true)
	
	if has_node("/root/TimeManager"):
		TimeManager.set_process(true)
