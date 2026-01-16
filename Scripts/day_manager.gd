extends Node

signal day_changed(new_day: int, date_text: String)
signal all_quests_completed
signal day_transition_started

var current_day: int = 1
var all_quests_done: bool = false

var day_dates: Array[String] = [
	"27/10/2056",  # วันที่ 1
	"28/10/2056",  # วันที่ 2
	"2/11/2056",   # วันที่ 3 (ข้ามไปเลย)
	"3/11/2056",   # วันที่ 4
	"4/11/2056",   # วันที่ 5
]

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
	
	print("[DayManager] ===== เริ่มเปลี่ยนวัน =====")
	print("[DayManager] วันเก่า: %d" % current_day)
	
	# ส่งสัญญาณให้ TransitionManager เริ่มทำ transition
	day_transition_started.emit()
	
	current_day += 1
	all_quests_done = false
	
	var date_text = get_current_date_text()
	print("[DayManager] วันใหม่: %d (%s)" % [current_day, date_text])
	
	# รอ transition จบ (2 วินาที ตาม TransitionManager)
	await get_tree().create_timer(2.0).timeout
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	print("[DayManager] ส่งสัญญาณ day_changed")
	day_changed.emit(current_day, date_text)
	
	await get_tree().create_timer(0.5).timeout
	_check_daily_progress()
	
	print("[DayManager] ===== เปลี่ยนวันเสร็จสิ้น =====")
	return true

func get_current_day() -> int:
	return current_day

func get_current_date_text() -> String:
	"""ดึงวันที่ของวันปัจจุบัน"""
	var index = current_day - 1
	if index >= 0 and index < day_dates.size():
		return day_dates[index]
	return "??/??/????"

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
