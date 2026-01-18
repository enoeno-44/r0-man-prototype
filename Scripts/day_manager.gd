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
	"29/10/2056",
	"30/10/2056",
	"4/11/2056",
	"5/11/2056",
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
	
	_freeze_player(true)
	_hide_hud()
	
	day_transition_started.emit()
	
	current_day += 1
	all_quests_done = false
	if current_day == 6:
		await get_tree().create_timer(5.0).timeout  # จอดำนาน 5 วินาที
	else:
		await get_tree().create_timer(2.0).timeout
	var date_text = get_current_date_text()
	print("[DayManager] เปลี่ยนเป็นวันที่ %d (%s)" % [current_day, date_text])
	
	# รอ transition จบ
	await get_tree().create_timer(2.0).timeout
	
	TimeManager.hour = 6
	TimeManager.minute = 0
	
	day_changed.emit(current_day, date_text)
	
	if has_node("/root/SystemDialogueManager"):
		print("[DayManager] รอ System Dialogue...")
		await SystemDialogueManager.dialogue_finished
		print("[DayManager] System Dialogue จบแล้ว")
	
	_freeze_player(false)
	
	await get_tree().create_timer(0.5).timeout
	_check_daily_progress()
	
	print("[DayManager] เปลี่ยนวันเสร็จสิ้น")
	return true

func _freeze_player(freeze: bool):
	"""หยุด/ปลดล็อคผู้เล่น"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)
	print("[DayManager] ผู้เล่น %s" % ("หยุด" if freeze else "ปลดล็อค"))

func _hide_hud():
	"""ซ่อน HUD หลัก"""
	if has_node("/root/HUDManager"):
		var hud = get_node("/root/HUDManager")
		hud.hide()
		print("[DayManager] ซ่อน HUD (HUDManager)")
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			hud.hide()
		print("[DayManager] ซ่อน HUD (%d nodes)" % hud_nodes.size())

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
