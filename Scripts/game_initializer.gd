# game_initializer.gd
# แนบ script นี้กับ Node ใน Game Scene (เช่น root node)
extends Node

var is_initialized: bool = false

func _ready():
	# ป้องกันการเริ่มต้นซ้ำ
	if is_initialized:
		return
	
	is_initialized = true
	# เปิดการทำงานของ Managers ทั้งหมด
	_enable_all_managers()
	
	# รอ 1 frame แล้วค่อยเริ่ม opening transition
	await get_tree().process_frame
	
	# ถ้ามาจากการ Continue/Load จะไม่แสดง opening
	if _is_fresh_start():
		_start_opening_sequence()
	else:
		# ถ้าเป็นการเล่นต่อ ให้โหลดตำแหน่งผู้เล่น
		SaveManager.restore_player_position()
		_show_hud()
		
		# *** FIX: จัดการ BGM และ Glitch หลังโหลดเกม ***
		_handle_loaded_game_state()

func _enable_all_managers():
	# เปิด TransitionManager
	if has_node("/root/TransitionManager"):
		TransitionManager.show()
		TransitionManager.set_process(true)
	
	# เปิด SystemDialogueManager
	if has_node("/root/SystemDialogueManager"):
		SystemDialogueManager.set_process(true)
	
	# เปิด TimeManager
	if has_node("/root/TimeManager"):
		TimeManager.set_process(true)
	
func _is_fresh_start() -> bool:
	# ตรวจสอบว่าเป็นการเริ่มเกมใหม่หรือไม่
	# ถ้า current_day = 1 และไม่มี meta data จาก SaveManager = เริ่มใหม่
	return DayManager.get_current_day() == 1 and not SaveManager.has_meta("player_position")

func _start_opening_sequence():
	# เรียก opening fade in จาก TransitionManager
	if has_node("/root/TransitionManager"):
		TransitionManager.opening_fade_in()

func _show_hud():
	# แสดง HUD ทันทีสำหรับการเล่นต่อ
	if has_node("/root/HUDManager"):
		var hud = get_node("/root/HUDManager")
		hud.show()
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			hud.show()

# *** FIX: ฟังก์ชันใหม่สำหรับจัดการสถานะหลังโหลดเกม ***
func _handle_loaded_game_state():
	var current_day = DayManager.get_current_day()
	
	# ถ้าเป็นวันที่ 6
	if current_day == 6:
		print("[GameInitializer] โหลดวันที่ 6 - เปิด Glitch")
		
		# รอให้ scene โหลดเสร็จสมบูรณ์
		await get_tree().process_frame
		await get_tree().process_frame
		
		# เปิด Glitch
		if has_node("/root/GlitchManager"):
			GlitchManager.force_check_and_activate()
		
		# ไม่เล่น BGM (วันที่ 6 ไม่มีเพลง)
		print("[GameInitializer] วันที่ 6 - ไม่เล่น BGM")
	else:
		# วันอื่นๆ เล่น BGM ปกติ
		print("[GameInitializer] โหลดวันที่ %d - เล่น BGM" % current_day)
		
		# เล่นเพลงหลังโหลดเกม (ไม่ใช่วันที่ 6)
		if has_node("/root/AudioManager"):
			# ใช้ delay เล็กน้อยเพื่อให้ scene เริ่มต้นเสร็จ
			await get_tree().create_timer(0.5).timeout
			AudioManager.play_random_bgm(2.0)
