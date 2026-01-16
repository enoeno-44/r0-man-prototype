# AutoLoad: QuestManager
# จัดการ quest ทั้งหมดในเกม
extends Node

signal quest_completed(quest_id: String)

var quests: Dictionary = {}

func _ready():
	_initialize_quests()

func _initialize_quests():
	# วันที่ 1
	register_quest("trashbin_a", "ทำลายขยะ จุด A", 1)
	register_quest("trashcan_a", "ทำลายขยะ จุด B", 1)
	register_quest("trashcan_b", "ทำลายขยะ จุด C", 1)
	register_quest("trash_a", "เก็บขยะ จุด D", 1)
	
	# วันที่ 2
	register_quest("trashcan_c", "ทำลายขยะ จุด E", 2)
	register_quest("trashbin_b", "ทำลายขยะ จุด F", 2)
	register_quest("trash_b", "เก็บขยะ จุด G", 2)
	
	# วันที่ 3
	register_quest("fence_repair", "ซ่อมรั้ว", 3)
	
	# Quest ของ NPC (hidden = ไม่แสดงใน panel)
	register_quest("npc_grandma_day1", "คุยกับยายละไม", 1, "hidden")

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
