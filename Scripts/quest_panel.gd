extends Control

@onready var quest_list := $MarginContainer/VBoxContainer/questlist

func _ready():
	QuestManager.quest_completed.connect(_on_quest_completed)
	update_quest_ui()

func update_quest_ui():
	quest_list.clear()
	for q in QuestManager.get_all_quests():
		if q.done:
			quest_list.append_text("• [s][color=gray]%s[/color][/s]\n" % q.text)
		else:
			quest_list.append_text("• %s\n" % q.text)

func _on_quest_completed(index: int):
	update_quest_ui()
