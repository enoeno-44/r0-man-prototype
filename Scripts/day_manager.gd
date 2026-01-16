# AutoLoad: DayManager
# จัดการวันที่และการเปลี่ยนวัน
extends Node

signal day_changed(new_day: int, date_text: String)
signal all_quests_completed
signal day_transition_started

var current_day: int = 1
var all_quests_done: bool = false

var day_dates: Array[String] = [
	"27/10/2056",
	"28/10/2056",
	"2/11/2056",
	"3/11/2056",
	"4/11/2056",
]

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	_check_daily_progress()

func _on_quest_completed(_quest_id: String):
	await get_tree().create_timer(0.1).timeout
	_check_daily_progress()

func _check_daily_progress():
	var old_status = all_quests_done
	var completed = QuestManager.get_completed_count_for_day(current_day)
	var total = QuestManager.get_total_quests_for_day(current_day)
	all_quests_done = completed >= total and total > 0
	
	if all_quests_done and not old_status:
		print("[DayManager] ภารกิจวันที่ %d ครบแล้ว" % current_day)
		all_quests_completed.emit()

func can_advance_day() -> bool:
	return all_quests_done

func advance_to_next_day():
	if not can_advance_day():
		print("[DayManager] ยังทำภารกิจไม่ครบ")
		return false
	
	print("[DayManager] กำลังเปลี่ยนจากวันที่ %d" % current_day)
	
	day_transition_started.emit()
	
	current_day += 1
	all_quests_done = false
	
	var date_text = get_current_date_text()
	print("[DayManager] เปลี่ยนเป็นวันที่ %d (%s)" % [current_day, date_text])
	
	# รอ transition จบ
	await get_tree().create_timer(2.0).timeout
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	day_changed.emit(current_day, date_text)
	
	await get_tree().create_timer(0.5).timeout
	_check_daily_progress()
	
	print("[DayManager] เปลี่ยนวันเสร็จสิ้น")
	return true

func get_current_day() -> int:
	return current_day

func get_current_date_text() -> String:
	var index = current_day - 1
	if index >= 0 and index < day_dates.size():
		return day_dates[index]
	return "??/??/????"

func get_completed_count() -> int:
	return QuestManager.get_completed_count_for_day(current_day)

func get_total_quests_today() -> int:
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
