extends Node

signal day_completed
signal day_changed(new_day: int)
signal all_quests_completed

var current_day: int = 1
var all_quests_done: bool = false

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	_check_daily_progress()

func _on_quest_completed(_quest_id: String):
	"""ตรวจสอบทุกครั้งที่ทำ quest เสร็จ"""
	await get_tree().create_timer(0.1).timeout
	_check_daily_progress()

func _check_daily_progress():
	"""ตรวจสอบว่าทำภารกิจของวันนี้ครบหรือยัง"""
	var old_status = all_quests_done
	all_quests_done = is_all_daily_quests_done()
	
	if all_quests_done and not old_status:
		print("[DayManager] ภารกิจวันที่ %d เสร็จสมบูรณ์" % current_day)
		all_quests_completed.emit()

func is_all_daily_quests_done() -> bool:
	"""เช็คว่าภารกิจของวันนี้ทำครบหรือยัง"""
	var completed = QuestManager.get_completed_count_for_day(current_day)
	var total = QuestManager.get_total_quests_for_day(current_day)
	return completed >= total and total > 0

func can_advance_day() -> bool:
	"""เช็คว่าสามารถผ่านไปวันถัดไปได้หรือไม่"""
	return all_quests_done

func advance_to_next_day():
	"""ไปวันถัดไป"""
	if not can_advance_day():
		print("[DayManager] ยังทำภารกิจไม่ครบ")
		return false
	
	current_day += 1
	all_quests_done = false
	
	print("[DayManager] เข้าสู่วันที่ %d" % current_day)
	
	# รีเซ็ตเวลา
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	# ส่ง signal ก่อนเพื่อให้ระบบอื่นอัปเดต
	day_changed.emit(current_day)
	
	await get_tree().create_timer(0.5).timeout
	_check_daily_progress()
	
	return true

func get_current_day() -> int:
	return current_day

func get_completed_count() -> int:
	"""นับว่าทำภารกิจวันนี้ไปกี่อันแล้ว"""
	return QuestManager.get_completed_count_for_day(current_day)

func get_total_quests_today() -> int:
	"""ภารกิจวันนี้ทั้งหมดกี่อัน"""
	return QuestManager.get_total_quests_for_day(current_day)

func get_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"all_quests_done": all_quests_done
	}

func load_save_data(data: Dictionary):
	if "current_day" in data:
		current_day = data.current_day
	if "all_quests_done" in data:
		all_quests_done = data.all_quests_done
