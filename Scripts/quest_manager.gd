# AutoLoad: QuestManager
# จัดการ quest ทั้งหมดในเกม
extends Node

signal quest_completed(quest_id: String)

var quests: Dictionary = {}

func _ready():
	_initialize_quests()

func _initialize_quests():
	
	# วันที่ 1
	register_quest("trash_1", "ทำลายขยะ โซน A", 1)
	register_quest("trash_2", "ทำลายขยะ โซน C", 1)
	register_quest("trash_3", "ทำลายขยะ โซน D", 1)
	
	# วันที่ 2
	register_quest("trash_4", "ทำลายขยะ โซน A", 2)
	register_quest("trash_5", "ทำลายขยะ โซน C", 2)
	register_quest("npc_1_day2", "คุยกับnpc1", 2, "hidden")
	register_quest("trash_6", "ทำลายขยะ โซน B", 2)
	register_quest("npc_2_day2", "คุยกับnpc2", 2, "hidden")
	
	# วันที่ 3
	register_quest("trash_7", "ทำลายขยะ โซน C", 3)
	register_quest("npc_3_day3", "คุยกับnpc3", 3, "hidden")
	register_quest("trash_8", "ทำลายขยะ โซน D", 3)
	register_quest("npc_4_day3", "คุยกับnpc4", 3, "hidden")
	register_quest("trash_9", "ทำลายขยะ โซน D", 3)
	
	# วันที่ 4
	register_quest("trash_10", "ทำลายขยะ โซน B", 4)
	register_quest("npc_5_day4", "คุยกับnpc5", 4, "hidden")
	register_quest("trash_11", "ทำลายขยะ โซน B", 4)
	register_quest("npc_6_day4", "คุยกับnpc6", 4, "hidden")
	register_quest("trash_12", "ทำลายขยะ โซน D", 4)
	
	# วันที่ 5
	register_quest("trash_13", "ทำลายขยะ โซน B", 5)
	register_quest("trash_14", "ทำลายขยะ โซน C", 5)
	register_quest("npc_7_day5", "คุยกับnpc7", 5, "hidden")
	register_quest("trash_15", "ทำลายขยะ โซน A", 5)
	register_quest("npc_8_day5", "คุยกับnpc8", 5, "hidden")
	
	# วันที่ 6
	register_quest("trash_16", "ทำลายขยะ โซน B", 6)
	register_quest("trash_17", "ทำลายขยะ โซน B", 6)
	register_quest("unknown_npc", "iknowyou?", 6, "hidden")


func register_quest(quest_id: String, quest_name: String, day: int, quest_type: String = "normal"):
	quests[quest_id] = {
		"name": quest_name,
		"done": false,
		"day": day,
		"type": quest_type
	}

func complete_quest(quest_id: String):
	if quest_id not in quests:
		push_error("[QuestManager] ไม่พบ quest_id: " + quest_id)
		return
	
	if quests[quest_id].done:
		return
	
	quests[quest_id].done = true
	quest_completed.emit(quest_id)
	print("[QuestManager] เสร็จสิ้น: " + quests[quest_id].name)

func is_quest_done(quest_id: String) -> bool:
	return quest_id in quests and quests[quest_id].done

func get_quests_for_day(day: int, include_hidden: bool = false) -> Array:
	var result = []
	for quest_id in quests.keys():
		var quest = quests[quest_id]
		if quest.day != day:
			continue
		if not include_hidden and quest.type == "hidden":
			continue
		
		result.append({
			"id": quest_id,
			"name": quest.name,
			"done": quest.done,
			"type": quest.type
		})
	return result

func get_completed_count_for_day(day: int) -> int:
	var count = 0
	for quest_id in quests.keys():
		var quest = quests[quest_id]
		if quest.day == day and quest.done:
			count += 1
	return count

func get_total_quests_for_day(day: int) -> int:
	var count = 0
	for quest_id in quests.keys():
		if quests[quest_id].day == day:
			count += 1
	return count

func get_save_data() -> Dictionary:
	return {"quests": quests}

func load_save_data(data: Dictionary):
	if "quests" in data:
		quests = data.quests
