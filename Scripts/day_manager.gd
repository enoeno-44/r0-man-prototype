# AutoLoad: DayManager
# day_manager.gd
extends Node

signal day_changed(new_day: int, date_text: String)
signal all_quests_completed
signal day_transition_started

var current_day: int = 1
var max_day_reached: int = 1
var all_quests_done: bool = false

var day_dates: Array[String] = [
	"27/10/2056", "28/10/2056", "29/10/2056",
	"30/10/2056", "5/11/2056", "6/11/2056",
]

# เพิ่ม Chapter สำหรับแต่ละวัน
var day_chapters: Array[String] = [
	"โปรโตคอลของเช้าวันใหม่", "นอกเหนือจากคำสั่ง", "โกโก้?",
	"ค่าที่ลดลง", "อุ่นกว่าปกติ", "ฉันเคยอยู่ที่นี่",
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
		all_quests_completed.emit()

func can_advance_day() -> bool:
	return all_quests_done

func advance_to_next_day():
	if not can_advance_day():
		return false
	
	_freeze_player(true)
	_hide_hud()
	day_transition_started.emit()
	
	current_day += 1
	
	# อัปเดต max_day_reached
	if current_day > max_day_reached:
		max_day_reached = current_day
	
	all_quests_done = false
	
	if current_day == 6:
		await get_tree().create_timer(5.0).timeout
		AudioManager.pause_bgm()
	else:
		await get_tree().create_timer(2.0).timeout
	
	var date_text = get_current_date_text()
	await get_tree().create_timer(2.0).timeout
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	day_changed.emit(current_day, date_text)
	
	if has_node("/root/SystemDialogueManager"):
		await SystemDialogueManager.dialogue_finished
	
	_freeze_player(false)
	await get_tree().create_timer(0.5).timeout
	_check_daily_progress()
	
	return true

func _freeze_player(freeze: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)

func _hide_hud():
	if has_node("/root/HUDManager"):
		var hud = get_node("/root/HUDManager")
		hud.hide()
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			hud.hide()

func get_current_day() -> int:
	return current_day

func get_current_date_text() -> String:
	var index = current_day - 1
	if index >= 0 and index < day_dates.size():
		return day_dates[index]
	return "??/??/????"

# ฟังก์ชันใหม่: ดึง Chapter
func get_current_chapter() -> String:
	var index = current_day - 1
	if index >= 0 and index < day_chapters.size():
		return day_chapters[index]
	return "Chapter ?"

# ฟังก์ชันใหม่: ดึงข้อความรวม Chapter + วันที่
func get_chapter_and_date() -> String:
	return get_current_chapter() + "\n" + get_current_date_text()

func get_completed_count() -> int:
	return QuestManager.get_completed_count_for_day(current_day)

func get_total_quests_today() -> int:
	return QuestManager.get_total_quests_for_day(current_day)

# ฟังก์ชันใหม่: ตรวจสอบว่าวันนั้นๆ ปลดล็อกแล้วหรือยัง
func is_day_unlocked(day: int) -> bool:
	return day <= max_day_reached

func get_save_data() -> Dictionary:
	return {
		"current_day": current_day,
		"max_day_reached": max_day_reached,  # เพิ่มตัวแปรนี้
		"all_quests_done": all_quests_done
	}

func load_save_data(data: Dictionary):
	if "current_day" in data:
		current_day = data.current_day
	if "max_day_reached" in data:
		max_day_reached = data.max_day_reached
	else:
		# ถ้าไม่มีข้อมูล max_day_reached (เซฟเก่า) ให้ใช้ current_day แทน
		max_day_reached = current_day
	if "all_quests_done" in data:
		all_quests_done = data.all_quests_done
