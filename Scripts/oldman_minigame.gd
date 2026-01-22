# box_breaking_minigame.gd
extends CanvasLayer

signal completed  # สัญญาณเมื่อเล่นจบ

#@onready var panel = $Panel
@onready var title_label = $GamePanel/MarginContainer/VBoxContainer/TitleLabel
@onready var instruction_label = $GamePanel/MarginContainer/VBoxContainer/InstructionLabel
@onready var progress_label = $GamePanel/MarginContainer/VBoxContainer/ProgressLabel
@onready var box_spawn_point = $BoxSpawnPoint

# โหลด Box Scene
var box_scene = preload("res://Minigames/breakable_box.tscn")

var total_boxes: int = 10  # จำนวนกล่องที่จะสร้าง
var destroyed_boxes: int = 0
var is_active: bool = false
var spawned_boxes: Array = []

func _ready():
	hide()  # ซ่อนตอนเริ่มต้น
	
	# ถ้าเป็น standalone scene (ทดสอบ)
	if get_parent() == get_tree().root:
		await get_tree().create_timer(0.5).timeout  # รอให้ scene โหลดเสร็จ
		start_minigame()

func start_minigame():
	"""เริ่มมินิเกม"""
	print("[BoxBreaking] เริ่มมินิเกม")
	show()
	is_active = true
	destroyed_boxes = 0
	
	# ลบกล่องเก่า (ถ้ามี)
	_clear_boxes()
	
	# สร้างกล่องใหม่
	_spawn_boxes()
	
	# อัปเดต UI
	_update_ui()

func _clear_boxes():
	"""ลบกล่องเก่าทั้งหมด"""
	for box in spawned_boxes:
		if is_instance_valid(box):
			box.queue_free()
	spawned_boxes.clear()

func _spawn_boxes():
	"""สร้างกล่องทั้งหมด"""
	var spawn_positions = [
		Vector2(-200, -100),
		Vector2(-100, -100),
		Vector2(0, -100),
		Vector2(100, -100),
		Vector2(200, -100),
		Vector2(-50, -200),
	]
	
	for i in range(total_boxes):
		var box = box_scene.instantiate()
		
		# เพิ่มเข้า scene
		add_child(box)
		spawned_boxes.append(box)
		
		# ตั้งตำแหน่ง (สุ่มเล็กน้อย)
		if i < spawn_positions.size():
			var base_pos = box_spawn_point.global_position + spawn_positions[i]
			box.global_position = base_pos + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		else:
			# ถ้ามากกว่า 6 ให้สุ่มตำแหน่ง
			box.global_position = box_spawn_point.global_position + Vector2(
				randf_range(-250, 250),
				randf_range(-200, -100)
			)
		
		# สุ่มสีให้แต่ละกล่อง
		var colors = [
			Color("8B4513"),  # น้ำตาล
			Color("A0522D"),  # น้ำตาลแดง
			Color("D2691E"),  # ช็อกโกแลต
			Color("CD853F"),  # น้ำตาลทอง
		]
		box.box_color = colors[i % colors.size()]
		if box.has_node("Sprite2D"):
			box.get_node("Sprite2D").modulate = box.box_color
		
		# Connect signal
		box.box_destroyed.connect(_on_box_destroyed)
		
		print("[BoxBreaking] สร้างกล่องที่ %d" % (i + 1))

func _on_box_destroyed():
	"""เมื่อกล่องถูกทำลาย"""
	destroyed_boxes += 1
	print("[BoxBreaking] ทำลายกล่อง %d/%d" % [destroyed_boxes, total_boxes])
	
	_update_ui()
	
	# เช็ควาจบหรือยัง
	if destroyed_boxes >= total_boxes:
		_complete_minigame()

func _update_ui():
	"""อัปเดต UI"""
	var remaining = total_boxes - destroyed_boxes
	progress_label.text = "เหลืออีก: %d/%d" % [remaining, total_boxes]
	
	if destroyed_boxes >= total_boxes:
		title_label.text = "เสร็จสิ้น!"
		title_label.modulate = Color.GREEN
		instruction_label.text = "ยอดเยี่ยม!"
	else:
		title_label.text = "ทำลายขยะทั้งหมด!"
		title_label.modulate = Color.WHITE
		instruction_label.text = "กดค้างที่ขยะเพื่อทำลาย"

func _complete_minigame():
	"""จบมินิเกม"""
	print("[BoxBreaking] มินิเกมเสร็จสิ้น!")
	is_active = false
	
	# แสดงข้อความเสร็จ 2 วินาที
	await get_tree().create_timer(2.0).timeout
	
	# ลบกล่องที่เหลือ
	_clear_boxes()
	
	# ปลดล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	
	# ส่งสัญญาณว่าเสร็จแล้ว
	completed.emit()
	print("[BoxBreaking] ส่งสัญญาณ 'completed'")
