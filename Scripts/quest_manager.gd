extends Node

signal quest_completed(index: int)

var quests = [
	{ "text": "เก็บขยะ จุด A", "done": false },
	{ "text": "เก็บขยะ จุด B", "done": false },
	{ "text": "ซ่อมป้าย จุด A", "done": false },
	{ "text": "ทำความสะอาดสวน", "done": false },
	{ "text": "ซ่อมรั้ว", "done": false },
]

func complete_quest(index: int):
	if index >= 0 and index < quests.size() and not quests[index].done:
		quests[index].done = true
		quest_completed.emit(index)
		print("✓ Quest completed: %s" % quests[index].text)

func is_quest_done(index: int) -> bool:
	if index >= 0 and index < quests.size():
		return quests[index].done
	return false

func get_all_quests() -> Array:
	return quests
