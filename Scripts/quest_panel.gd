extends Control

@onready var quest_list := $MarginContainer/VBoxContainer/questlist
@onready var day_label := $MarginContainer/VBoxContainer/DayLabel

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	DayManager.day_changed.connect(_on_day_changed)
	update_quest_ui()

func update_quest_ui():
	quest_list.clear()
	
	var current_day = DayManager.get_current_day()
	var day_quests = QuestManager.get_quests_for_day(current_day)
	
	for quest_data in day_quests:
		if quest_data.done:
			quest_list.append_text("• [s][color=gray]%s[/color][/s]\n" % quest_data.name)
		else:
			quest_list.append_text("• %s\n" % quest_data.name)
	
	if day_label:
		var completed = DayManager.get_completed_count()
		var total = DayManager.get_total_quests_today()
		day_label.text = "วันที่ %d - ภารกิจ: %d/%d" % [current_day, completed, total]

func _on_quest_completed(_quest_id: String):
	update_quest_ui()

func _on_day_changed(_new_day: int, _date_text: String):
	print("[QuestPanel] อัปเดต UI")
	update_quest_ui()
