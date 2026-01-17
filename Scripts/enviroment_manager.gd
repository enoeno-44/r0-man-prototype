# จัดการ environment ของแต่ละวัน
extends Node2D

@export var day1_node: Node2D
@export var day2_node: Node2D
@export var day3_node: Node2D
@export var day4_node: Node2D
@export var day5_node: Node2D
@export var day6_node: Node2D

var day_nodes: Dictionary = {}

func _ready():
	day_nodes[1] = day1_node
	day_nodes[2] = day2_node
	day_nodes[3] = day3_node
	day_nodes[4] = day4_node
	day_nodes[5] = day5_node
	day_nodes[6] = day6_node
	
	DayManager.day_changed.connect(_on_day_changed)
	_update_environment(DayManager.get_current_day())

func _on_day_changed(new_day: int, _date_text: String):
	print("[EnvManager] เปลี่ยน environment เป็นวันที่ %d" % new_day)
	_update_environment(new_day)

func _update_environment(day: int):
	# ปิดทุก node
	for day_num in day_nodes.keys():
		if day_nodes[day_num]:
			_set_node_active(day_nodes[day_num], false)
	
	# เปิดเฉพาะ node ของวันนี้
	if day in day_nodes and day_nodes[day]:
		_set_node_active(day_nodes[day], true)
		print("[EnvManager] แสดง " + day_nodes[day].name)
	else:
		print("[EnvManager] ไม่พบ node สำหรับวันที่ %d" % day)

func _set_node_active(node: Node2D, is_active: bool):
	if not node:
		return
	
	node.visible = is_active
	node.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
