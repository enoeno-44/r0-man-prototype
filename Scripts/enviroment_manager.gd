extends Node2D

# เก็บ reference ของ Node container แต่ละวัน
@export var day_containers: Array[Node2D] = []

func _ready():
	DayManager.day_changed.connect(_on_day_changed)
	
	# ถ้าไม่ได้ assign ใน Inspector ให้หา child nodes อัตโนมัติ
	if day_containers.is_empty():
		_auto_find_day_containers()
	
	_update_environment(DayManager.get_current_day())

func _auto_find_day_containers():
	"""หา day containers อัตโนมัติจากชื่อ Day1, Day2, Day3, ..."""
	for child in get_children():
		if child is Node2D and child.name.begins_with("Day"):
			day_containers.append(child)
			print("[EnvManager] พบ container: %s" % child.name)
	
	# เรียงตามชื่อ
	day_containers.sort_custom(func(a, b): return a.name < b.name)

func _on_day_changed(new_day: int):
	print("[EnvManager] กำลังเปลี่ยน environment เป็นวันที่ %d" % new_day)
	_update_environment(new_day)

func _update_environment(day: int):
	"""แสดง/ซ่อน Day containers ตามวัน"""
	
	for i in range(day_containers.size()):
		var container = day_containers[i]
		var should_show = (i == day - 1)  # day 1 = index 0
		
		_set_container_active(container, should_show)
		
		if should_show:
			print("[EnvManager] แสดง %s" % container.name)

func _set_container_active(container: Node2D, is_active: bool):
	"""เปิด/ปิด container ทั้งหมด (visible + process)"""
	if not container:
		return
	
	container.visible = is_active
	container.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
	
	# เปิด/ปิด collision ของ objects ด้านใน
	_set_collision_recursive(container, is_active)

func _set_collision_recursive(node: Node, enabled: bool):
	"""เปิด/ปิด collision แบบ recursive"""
	for child in node.get_children():
		if child is CollisionShape2D or child is CollisionPolygon2D:
			child.disabled = not enabled
		_set_collision_recursive(child, enabled)
