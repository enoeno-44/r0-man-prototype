extends Node2D

@export var arrow_distance: float = 60.0
@export var arrow_color: Color = Color(1, 0.8, 0, 1)
@export var pulse_speed: float = 2.0
@export var pulse_scale: float = 0.2

var player: CharacterBody2D
var current_target: Area2D = null
var quest_areas: Array[Area2D] = []

@onready var arrow_sprite: Polygon2D = _get_or_create_arrow()

var time: float = 0.0

func _get_or_create_arrow() -> Polygon2D:
	"""ค้นหา Arrow node หรือสร้างใหม่ถ้าไม่มี"""
	var arrow = get_node_or_null("Arrow")
	
	if not arrow:
		print("[QuestArrow] ไม่พบ Arrow node, กำลังสร้างใหม่")
		arrow = Polygon2D.new()
		arrow.name = "Arrow"
		add_child(arrow)
		print("[QuestArrow] สร้าง Arrow node สำเร็จ")
	
	return arrow

func _ready():
	z_index = 100
	
	if not arrow_sprite:
		push_error("[QuestArrow] ไม่พบ Arrow node")
		return
	
	_create_arrow_shape()
	arrow_sprite.color = arrow_color
	
	print("[QuestArrow] เริ่มต้น")
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("[QuestArrow] ไม่พบ Player")
		return
	
	print("[QuestArrow] พบ Player: %s" % player.name)
	
	_register_quest_areas()
	_update_target()
	
	QuestManager.quest_completed.connect(_on_quest_completed)
	DayManager.all_quests_completed.connect(_on_all_quests_completed)
	DayManager.day_changed.connect(_on_day_changed)
	
	print("[QuestArrow] พร้อมใช้งาน")

func _process(delta):
	if not player:
		visible = false
		return
	
	# ซ่อนถ้าทำภารกิจครบแล้ว
	if DayManager.can_advance_day():
		visible = false
		return
	
	# ซ่อนถ้าไม่มีเป้าหมาย
	if not current_target:
		visible = false
		return
	
	# ซ่อนถ้าผู้เล่นเข้าไปใน ArrowHideArea
	var hide_area = current_target.get_node_or_null("ArrowHideArea")
	if hide_area and hide_area is Area2D:
		var overlapping = hide_area.get_overlapping_bodies()
		if player in overlapping:
			visible = false
			return
	
	visible = true
	time += delta
	
	global_position = player.global_position
	
	var direction = (current_target.global_position - player.global_position).normalized()
	rotation = direction.angle()
	
	var pulse = 1.0 + sin(time * pulse_speed) * pulse_scale
	scale = Vector2(pulse, pulse)

func _create_arrow_shape():
	"""สร้างรูปลูกศร"""
	var points = PackedVector2Array([
		Vector2(arrow_distance + 15, 0),
		Vector2(arrow_distance, -8),
		Vector2(arrow_distance + 5, 0),
		Vector2(arrow_distance, 8),
	])
	arrow_sprite.polygon = points

func _register_quest_areas():
	"""ค้นหาและลงทะเบียน quest areas ของวันนี้"""
	quest_areas.clear()
	var all_areas = get_tree().get_nodes_in_group("quest_area")
	
	print("[QuestArrow] พบ quest_area nodes: %d" % all_areas.size())
	
	if all_areas.is_empty():
		push_warning("[QuestArrow] ไม่พบ quest_area ในฉาก")
		return
	
	var current_day = DayManager.get_current_day()
	
	# เก็บเฉพาะ quest ของวันนี้
	for area in all_areas:
		if area is Area2D and area.has_method("_is_active"):
			if area.quest_day == current_day:
				quest_areas.append(area)
				print("[QuestArrow] ลงทะเบียน: %s (วันที่ %d)" % [area.quest_id, area.quest_day])
	
	print("[QuestArrow] ลงทะเบียนสำเร็จ: %d quest" % quest_areas.size())

func _update_target():
	"""อัปเดตเป้าหมายไปยัง quest ถัดไปที่ยังไม่เสร็จ"""
	current_target = null
	
	print("[QuestArrow] กำลังค้นหา quest ถัดไป")
	
	if DayManager.can_advance_day():
		print("[QuestArrow] ภารกิจครบแล้ว - ซ่อนลูกศร")
		visible = false
		return
	
	for area in quest_areas:
		var is_done = QuestManager.is_quest_done(area.quest_id)
		print("[QuestArrow] %s: %s" % [area.quest_id, "เสร็จแล้ว" if is_done else "ยังไม่เสร็จ"])
		
		if not is_done:
			current_target = area
			print("[QuestArrow] ชี้ไปที่: %s" % area.quest_id)
			visible = true
			break
	
	if not current_target:
		print("[QuestArrow] ไม่มี quest ที่ต้องทำ")
		visible = false

func _on_quest_completed(_quest_id: String):
	"""เมื่อทำ quest เสร็จ"""
	await get_tree().create_timer(0.5).timeout
	_update_target()

func _on_all_quests_completed():
	"""เมื่อทำภารกิจครบ"""
	print("[QuestArrow] ภารกิจครบแล้ว - ซ่อนลูกศร")
	visible = false
	current_target = null

func _on_day_changed(_new_day: int):
	"""เมื่อเปลี่ยนวัน"""
	print("[QuestArrow] เปลี่ยนวัน - ลงทะเบียนใหม่")
	await get_tree().create_timer(0.5).timeout
	_register_quest_areas()
	_update_target()

func set_arrow_color(color: Color):
	"""เปลี่ยนสีลูกศร"""
	arrow_color = color
	if arrow_sprite:
		arrow_sprite.color = color

func set_arrow_distance(distance: float):
	"""เปลี่ยนระยะห่างของลูกศร"""
	arrow_distance = distance
	_create_arrow_shape()
