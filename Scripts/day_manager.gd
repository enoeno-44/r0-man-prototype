extends Node

signal day_completed
signal day_changed(new_day: int)
signal all_quests_completed

var current_day: int = 1
var all_quests_done: bool = false

# กำหนดภารกิจแต่ละวัน (quest_index)
var daily_quests = {
	1: [0, 1],           # วันที่ 1: เก็บขยะ A, B
	2: [2],           # วันที่ 2: ซ่อมป้าย, ทำความสะอาดสวน
	3: [3],              # วันที่ 3: ซ่อมรั้ว
	# เพิ่มวันอื่นๆได้ตามต้องการ
}

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	_check_daily_progress()

func _on_quest_completed(_index: int):
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
	if current_day not in daily_quests:
		return false
	
	var today_quests = daily_quests[current_day]
	
	for quest_idx in today_quests:
		if not QuestManager.is_quest_done(quest_idx):
			return false
	
	return true

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
	day_changed.emit(current_day)
	
	# รีเซ็ตเวลา
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	_check_daily_progress()
	return true

func get_current_day() -> int:
	return current_day

func get_daily_quests(day: int = -1) -> Array:
	"""ดึงรายการภารกิจของวันที่กำหนด (default = วันปัจจุบัน)"""
	var target_day = day if day > 0 else current_day
	if target_day in daily_quests:
		return daily_quests[target_day]
	return []

func get_completed_count() -> int:
	"""นับว่าทำภารกิจวันนี้ไปกี่อันแล้ว"""
	var today_quests = get_daily_quests()
	var count = 0
	
	for quest_idx in today_quests:
		if QuestManager.is_quest_done(quest_idx):
			count += 1
	
	return count

func get_total_quests_today() -> int:
	"""ภารกิจวันนี้ทั้งหมดกี่อัน"""
	return get_daily_quests().size()

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
