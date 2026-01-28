# AutoLoad: SaveManager
# save_manager.gd
extends Node

const SAVE_FILE_PATH = "user://savegame.save"
const PERSISTENT_FILE_PATH = "user://persistent_data.save"  # เก็บข้อมูลที่ไม่ลบ

# เซฟข้อมูลทั้งหมด
func save_game():
	var save_data = {
		"current_day": DayManager.get_current_day(),
		"max_day_reached": DayManager.max_day_reached,
		"game_completed": false,  # จะถูกตั้งค่าเป็น true โดย EndGameManager
		"quests": QuestManager.get_save_data(),
		"time": {
			"hour": TimeManager.hour,
			"minute": TimeManager.minute
		},
		"player_position": _get_player_position(),
		"save_timestamp": Time.get_datetime_string_from_system(),
		"audio": AudioManager.get_save_data()  # เก็บเฉพาะ BGM ที่กำลังเล่น
	}
	
	# เช็คว่ามีการบันทึกเก่าที่จบเกมไปแล้วหรือไม่
	if has_save_file():
		var old_data = _read_save_file()
		if old_data and "game_completed" in old_data:
			save_data["game_completed"] = old_data["game_completed"]
	
	# *** FIX: บันทึก persistent data ทุกครั้งที่เซฟเกม ***
	save_persistent_data()
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[SaveManager] บันทึกเกมสำเร็จ - วันที่ %d (ปลดล็อกถึงวันที่ %d)" % [save_data.current_day, save_data.max_day_reached])
		return true
	else:
		print("[SaveManager] ไม่สามารถบันทึกเกมได้!")
		return false

# ฟังก์ชันใหม่: บันทึกว่าเกมจบแล้ว
func mark_game_completed():
	if not has_save_file():
		return
	
	var save_data = _read_save_file()
	if save_data:
		save_data["game_completed"] = true
		
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		if file:
			file.store_var(save_data)
			file.close()
			print("[SaveManager] ทำเครื่องหมายว่าเกมจบแล้ว")

# ฟังก์ชันใหม่: ตรวจสอบว่าเกมจบแล้วหรือยัง
func is_game_completed() -> bool:
	if not has_save_file():
		return false
	
	var save_data = _read_save_file()
	if save_data and "game_completed" in save_data:
		return save_data["game_completed"]
	return false

# ฟังก์ชันภายใน: อ่านไฟล์เซฟ
func _read_save_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return {}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		return data
	return {}

# โหลดข้อมูล
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveManager] ไม่พบไฟล์เซฟ")
		return false
	
	var save_data = _read_save_file()
	if save_data.is_empty():
		print("[SaveManager] ไม่สามารถอ่านไฟล์เซฟได้!")
		return false
	
	# โหลดข้อมูลกลับเข้าระบบ
	if "current_day" in save_data:
		DayManager.current_day = save_data.current_day
	
	if "max_day_reached" in save_data:
		DayManager.max_day_reached = save_data.max_day_reached
	else:
		# ถ้าไม่มีข้อมูล max_day_reached (เซฟเก่า) ให้ใช้ current_day แทน
		DayManager.max_day_reached = DayManager.current_day
	
	if "quests" in save_data:
		QuestManager.load_save_data(save_data.quests)
	
	if "time" in save_data:
		TimeManager.hour = save_data.time.hour
		TimeManager.minute = save_data.time.minute
	
	# เก็บตำแหน่งผู้เล่นไว้โหลดทีหลัง (ใน game scene)
	if "player_position" in save_data:
		set_meta("player_position", save_data.player_position)
	
	# โหลดเฉพาะ BGM ที่กำลังเล่น (การตั้งค่าเสียงโหลดแยกแล้ว)
	if "audio" in save_data:
		AudioManager.load_save_data(save_data.audio)
	
	# *** FIX: บังคับให้ DayManager เช็ค quest progress หลังโหลด ***
	DayManager._check_daily_progress()
	
	print("[SaveManager] โหลดเกมสำเร็จ - วันที่ %d (ปลดล็อกถึงวันที่ %d)" % [save_data.current_day, DayManager.max_day_reached])
	return true

# ตรวจสอบว่ามีไฟล์เซฟหรือไม่
func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

# ลบไฟล์เซฟ (สำหรับเริ่มเกมใหม่)
func delete_save():
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("[SaveManager] ลบไฟล์เซฟแล้ว")

# ดึงข้อมูลเบื้องต้นจากไฟล์เซฟ (ไม่โหลดเข้าเกม)
func get_save_info() -> Dictionary:
	if not has_save_file():
		return {}
	
	var save_data = _read_save_file()
	if save_data.is_empty():
		return {}
	
	var max_day = save_data.get("max_day_reached", save_data.get("current_day", 1))
	
	return {
		"day": save_data.get("current_day", 1),
		"max_day_reached": max_day,
		"game_completed": save_data.get("game_completed", false),  # เพิ่มข้อมูลนี้
		"date": DayManager.day_dates[save_data.get("current_day", 1) - 1] if save_data.get("current_day", 1) <= 6 else "??/??/????",
		"timestamp": save_data.get("save_timestamp", "Unknown")
	}

# ดึงตำแหน่งผู้เล่น
func _get_player_position() -> Vector2:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		return player.global_position
	return Vector2.ZERO

# เรียกใช้หลังโหลดเกมแล้ว (ใน game scene)
func restore_player_position():
	if has_meta("player_position"):
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = get_meta("player_position")
			remove_meta("player_position")

# รีเซ็ตเกมทั้งหมด (เริ่มใหม่)
# ฟังก์ชันใหม่: บันทึก persistent data (ข้อมูลที่ไม่ถูกลบเมื่อเริ่มเกมใหม่)
func save_persistent_data():
	var persistent_data = {
		"highest_day_reached": DayManager.max_day_reached
	}
	
	var file = FileAccess.open(PERSISTENT_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(persistent_data)
		file.close()
		print("[SaveManager] บันทึก persistent data: highest_day = %d" % persistent_data.highest_day_reached)

# ฟังก์ชันใหม่: โหลด persistent data
func load_persistent_data() -> int:
	if not FileAccess.file_exists(PERSISTENT_FILE_PATH):
		return 1  # ค่าเริ่มต้น
	
	var file = FileAccess.open(PERSISTENT_FILE_PATH, FileAccess.READ)
	if file:
		var data = file.get_var()
		file.close()
		if data and "highest_day_reached" in data:
			print("[SaveManager] โหลด persistent data: highest_day = %d" % data.highest_day_reached)
			return data.highest_day_reached
	
	return 1

func reset_game():
	# *** FIX: บันทึก max_day_reached ก่อนรีเซ็ต ***
	save_persistent_data()
	
	DayManager.current_day = 1
	# *** FIX: โหลด max_day จาก persistent file แทน ***
	DayManager.max_day_reached = load_persistent_data()
	DayManager.all_quests_done = false
	
	# รีเซ็ต quests ทั้งหมด
	for quest_id in QuestManager.quests.keys():
		QuestManager.quests[quest_id].done = false
	
	# *** FIX: รีเซ็ต ItemsManager ***
	ItemManager.items.clear()
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	# หมายเหตุ: ไม่รีเซ็ตการตั้งค่าเสียง (เก็บค่าที่ผู้เล่นตั้งไว้)
	
	print("[SaveManager] รีเซ็ตเกมแล้ว (เก็บ unlock ไว้ที่วัน %d)" % DayManager.max_day_reached)

# ฟังก์ชันใหม่: โหลดวันที่เฉพาะเจาะจง
func load_specific_day(day: int):
	# รีเซ็ตเกม
	DayManager.current_day = day
	DayManager.all_quests_done = false
	
	# ตั้งค่า quest ก่อนหน้าให้เสร็จ, quest วันที่เลือกและหลังจากนั้นให้ไม่เสร็จ
	for quest_id in QuestManager.quests.keys():
		var quest = QuestManager.quests[quest_id]
		if quest.day < day:
			quest.done = true
		else:
			quest.done = false
	
	# รีเซ็ตเวลา
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	# *** FIX: เช็ค quest progress หลังโหลดวัน ***
	DayManager._check_daily_progress()
	
	print("[SaveManager] โหลดวันที่ %d สำเร็จ" % day)

# ฟังก์ชันใหม่: รีเซ็ตทุกอย่างรวมถึง unlock (สำหรับเริ่มเกมใหม่แบบเริ่มต้นจริงๆ)
func reset_all_progress():
	"""รีเซ็ตทุกอย่างกลับไปเป็นเหมือนเล่นครั้งแรก"""
	# ลบ persistent data
	if FileAccess.file_exists(PERSISTENT_FILE_PATH):
		DirAccess.remove_absolute(PERSISTENT_FILE_PATH)
		print("[SaveManager] ลบ persistent data แล้ว")
	
	# รีเซ็ตทุกอย่าง
	DayManager.current_day = 1
	DayManager.max_day_reached = 1
	DayManager.all_quests_done = false
	
	for quest_id in QuestManager.quests.keys():
		QuestManager.quests[quest_id].done = false
	
	ItemManager.items.clear()
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	print("[SaveManager] รีเซ็ตทุกอย่างแล้ว (รวม unlock)")
