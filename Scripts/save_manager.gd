# AutoLoad: SaveManager
# save_manager.gd
extends Node

const SAVE_FILE_PATH = "user://savegame.save"

# เซฟข้อมูลทั้งหมด
func save_game():
	var save_data = {
		"current_day": DayManager.get_current_day(),
		"quests": QuestManager.get_save_data(),
		"time": {
			"hour": TimeManager.hour,
			"minute": TimeManager.minute
		},
		"player_position": _get_player_position(),
		"save_timestamp": Time.get_datetime_string_from_system(),
		"audio": AudioManager.get_save_data()
	}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()
		print("[SaveManager] บันทึกเกมสำเร็จ - วันที่ %d" % save_data.current_day)
		return true
	else:
		print("[SaveManager] ไม่สามารถบันทึกเกมได้!")
		return false

# โหลดข้อมูล
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveManager] ไม่พบไฟล์เซฟ")
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		
		# โหลดข้อมูลกลับเข้าระบบ
		if "current_day" in save_data:
			DayManager.current_day = save_data.current_day
		
		if "quests" in save_data:
			QuestManager.load_save_data(save_data.quests)
		
		if "time" in save_data:
			TimeManager.hour = save_data.time.hour
			TimeManager.minute = save_data.time.minute
		
		# เก็บตำแหน่งผู้เล่นไว้โหลดทีหลัง (ใน game scene)
		if "player_position" in save_data:
			set_meta("player_position", save_data.player_position)
			
		if "audio" in save_data:
			AudioManager.load_save_data(save_data.audio)
		
		print("[SaveManager] โหลดเกมสำเร็จ - วันที่ %d" % save_data.current_day)
		return true
	else:
		print("[SaveManager] ไม่สามารถอ่านไฟล์เซฟได้!")
		return false

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
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var save_data = file.get_var()
		file.close()
		return {
			"day": save_data.get("current_day", 1),
			"date": DayManager.day_dates[save_data.get("current_day", 1) - 1] if save_data.get("current_day", 1) <= 6 else "??/??/????",
			"timestamp": save_data.get("save_timestamp", "Unknown")
		}
	return {}

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
func reset_game():
	DayManager.current_day = 1
	DayManager.all_quests_done = false
	
	# รีเซ็ต quests ทั้งหมด
	for quest_id in QuestManager.quests.keys():
		QuestManager.quests[quest_id].done = false
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	print("[SaveManager] รีเซ็ตเกมแล้ว")
