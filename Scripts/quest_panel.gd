extends Control

@onready var quest_list := $MarginContainer/VBoxContainer/questlist
@onready var day_label := $MarginContainer/VBoxContainer/DayLabel  # เพิ่ม label แสดงวัน

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	DayManager.day_changed.connect(_on_day_changed)
	update_quest_ui()

func update_quest_ui():
	quest_list.clear()
	
	# แสดงเฉพาะ quest ของวันนี้
	var today_quests = DayManager.get_daily_quests()
	var all_quests = QuestManager.get_all_quests()
	
	for quest_idx in today_quests:
		if quest_idx < all_quests.size():
			var q = all_quests[quest_idx]
			if q.done:
				quest_list.append_text("• [s][color=gray]%s[/color][/s]\n" % q.text)
			else:
				quest_list.append_text("• %s\n" % q.text)
	
	# อัปเดต label วัน
	if day_label:
		var completed = DayManager.get_completed_count()
		var total = DayManager.get_total_quests_today()
		day_label.text = "วันที่ %d - ภารกิจ: %d/%d" % [DayManager.get_current_day(), completed, total]

func _on_quest_completed(index: int):
	update_quest_ui()

func _on_day_changed(new_day: int):
	print("[QuestPanel] อัปเดต UI สำหรับวันที่ %d" % new_day)
	update_quest_ui()
