extends Node2D

@export var arrow_distance: float = 60.0  # ระยะห่างจากผู้เล่น
@export var arrow_color: Color = Color(1, 0.8, 0, 1)  # สีทอง
@export var pulse_speed: float = 2.0
@export var pulse_scale: float = 0.2

var player: CharacterBody2D
var current_target: Area2D = null
var quest_areas: Array[Area2D] = []

@onready var arrow_sprite: Polygon2D = $Arrow

var time: float = 0.0

func _ready():
	_create_arrow_shape()
	arrow_sprite.color = arrow_color
	
	# รอ 1 เฟรมให้ scene โหลดเสร็จ
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	_register_all_quest_areas()
	_update_target()
	
	# เชื่อมต่อกับ QuestManager
	QuestManager.quest_completed.connect(_on_quest_completed)

func _process(delta):
	if not player or not current_target:
		visible = false
		return
	if current_target.overlaps_body(player):
		visible = false
		return
	visible = true
	time += delta
	
	# วางตำแหน่งให้อยู่กับผู้เล่น
	global_position = player.global_position
	
	# หมุนลูกศรไปทางเป้าหมาย
	var direction = (current_target.global_position - player.global_position).normalized()
	rotation = direction.angle()
	
	# Pulse effect
	var pulse = 1.0 + sin(time * pulse_speed) * pulse_scale
	scale = Vector2(pulse, pulse)

func _create_arrow_shape():
	"""สร้างรูปลูกศรด้วย Polygon2D"""
	var points = PackedVector2Array([
		Vector2(arrow_distance + 15, 0),      # หัวลูกศร
		Vector2(arrow_distance, -8),          # ปีกบน
		Vector2(arrow_distance + 5, 0),       # คอ
		Vector2(arrow_distance, 8),           # ปีกล่าง
	])
	arrow_sprite.polygon = points

func _register_all_quest_areas():
	"""ค้นหาและลงทะเบียน quest areas ทั้งหมดตามลำดับ quest_index"""
	var all_areas = get_tree().get_nodes_in_group("quest_area")
	
	if all_areas.is_empty():
		push_warning("ไม่พบ quest_area ในฉาก! อย่าลืมเพิ่ม quest_Objects ลงใน group 'quest_area'")
		return
	
	# เรียงตาม quest_index
	all_areas.sort_custom(func(a, b): return a.quest_index < b.quest_index)
	
	for area in all_areas:
		if area is Area2D:
			quest_areas.append(area)
	
	print("ลงทะเบียน Quest Areas: %d areas" % quest_areas.size())

func _update_target():
	"""อัปเดตเป้าหมายไปยัง quest ถัดไปที่ยังไม่เสร็จ"""
	current_target = null
	
	for area in quest_areas:
		var quest_idx = area.quest_index
		if not QuestManager.is_quest_done(quest_idx):
			current_target = area
			print("ลูกศรชี้ไปที่: %s (Quest %d)" % [area.name, quest_idx])
			break
	
	if not current_target:
		print("ทำ Quest ครบทุกอันแล้ว!")
		visible = false

func _on_quest_completed(_index: int):
	"""เมื่อทำ quest เสร็จ ให้ชี้ไปที่ quest ถัดไป"""
	await get_tree().create_timer(0).timeout
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
