extends Node

signal quest_completed(quest_id: String)

var quests: Dictionary = {}

func _ready():
	_initialize_quests()

func _initialize_quests():
	"""กำหนด quest ทั้งหมด"""
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
	
	# เควสต์ NPCs
	register_quest("npc_grandma_day1", "คุยกับยายละไม", 1, "hidden")
	
func register_quest(quest_id: String, quest_name: String, day: int, quest_type: String = "normal"):
	"""ลงทะเบียน quest quest_type: 'normal' = แสดงใน panel, 'hidden' = ไม่แสดง"""
	quests[quest_id] = {
		"name": quest_name,
		"done": false,
		"day": day,
		"type": quest_type  # ← เพิ่มฟิลด์นี้
	}

func complete_quest(quest_id: String):
	"""ทำ quest สำเร็จ"""
	if quest_id not in quests:
		push_error("[QuestManager] ไม่พบ quest_id: %s" % quest_id)
		return
	
	if quests[quest_id].done:
		print("[QuestManager] Quest %s ทำเสร็จแล้ว" % quest_id)
		return
	
	quests[quest_id].done = true
	quest_completed.emit(quest_id)
	print("[QuestManager] Quest สำเร็จ: %s" % quests[quest_id].name)

func is_quest_done(quest_id: String) -> bool:
	"""เช็คว่า quest เสร็จหรือยัง"""
	if quest_id in quests:
		return quests[quest_id].done
	return false

func get_quests_for_day(day: int, include_hidden: bool = false) -> Array:
	"""ดึง quest ของวันนี้ include_hidden: false = ไม่เอาแบบ hidden มาด้วย"""
	var day_quests = []
	for quest_id in quests.keys():
		var quest = quests[quest_id]
		if quest.day == day:
			if not include_hidden and quest.type == "hidden":
				continue
			day_quests.append({
				"id": quest_id,
				"name": quest.name,
				"done": quest.done,
				"type": quest.type
			})
	return day_quests

func reset_quests_for_day(day: int):
	"""รีเซ็ต quest ของวันที่กำหนด"""
	for quest_id in quests.keys():
		if quests[quest_id].day == day:
			quests[quest_id].done = false
			print("[QuestManager] รีเซ็ต quest: %s" % quest_id)

func get_completed_count_for_day(day: int) -> int:
	"""นับที่เสร็จแล้ว (รวม hidden)"""
	var count = 0
	for quest_id in quests.keys():
		var quest = quests[quest_id]
		if quest.day == day and quest.done:
			count += 1
	return count

func get_total_quests_for_day(day: int) -> int:
	"""นับ quest ทั้งหมด (รวม hidden)"""
	var count = 0
	for quest_id in quests.keys():
		if quests[quest_id].day == day:
			count += 1
	return count

func get_save_data() -> Dictionary:
	return { "quests": quests }

func load_save_data(data: Dictionary):
	if "quests" in data:
		quests = data.quests
