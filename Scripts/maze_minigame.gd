# maze_minigame.gd
extends CanvasLayer

signal completed

# UI References
@onready var title_label = $Panel/MarginContainer/VBoxContainer/TitleLabel
@onready var instruction_label = $Panel/MarginContainer/VBoxContainer/InstructionLabel
@onready var status_label = $Panel/MarginContainer/VBoxContainer/StatusLabel

# Game References
@onready var maze_container = $MazeContainer
@onready var item = $MazeContainer/Item
@onready var start_zone = $MazeContainer/StartZone

# Game State
var is_active: bool = false
var is_dragging: bool = false
var collision_count: int = 0
var max_collisions: int = 2
var mouse_offset: Vector2 = Vector2.ZERO

func _ready():
	hide()
	
	# ตั้งค่า Item
	if item:
		item.body_entered.connect(_on_item_collision)
		item.freeze = true  # หยุด physics ตอนเริ่มต้น
	
	# เช็คถ้ารันคนเดียว
	if get_parent() == get_tree().root:
		start_minigame()

func start_minigame():
	"""เริ่มเกม"""
	print("[MazeMinigame] เริ่มมินิเกม")
	show()
	is_active = true
	collision_count = 0
	_reset_item()
	_update_ui()

func _reset_item():
	"""รีเซ็ตไอเท็มกลับไปตำแหน่งเริ่มต้น"""
	if item and start_zone:
		item.global_position = start_zone.global_position
		item.linear_velocity = Vector2.ZERO
		item.angular_velocity = 0
		item.freeze = true

func _input(event):
	if not is_active or not item:
		return
	
	# เริ่มลาก
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# เช็คว่าคลิกโดนไอเท็มไหม
			var space_state = get_viewport().world_2d.direct_space_state
			var params = PhysicsPointQueryParameters2D.new()
			params.position = get_viewport().get_mouse_position()
			params.collide_with_bodies = true
			
			var results = space_state.intersect_point(params, 1)
			
			if results.size() > 0 and results[0].collider == item:
				is_dragging = true
				item.freeze = false
				mouse_offset = item.global_position - item.get_global_mouse_position()
				print("[MazeMinigame] เริ่มลากไอเท็ม")
		else:
			# ปล่อยลาก
			if is_dragging:
				is_dragging = false
				print("[MazeMinigame] ปล่อยไอเท็ม")
	
	# ลากไอเท็ม
	if event is InputEventMouseMotion and is_dragging:
		var target_pos = item.get_global_mouse_position() + mouse_offset
		item.linear_velocity = (target_pos - item.global_position) * 10

func _on_item_collision(body: Node):
	"""เมื่อไอเท็มชนผนัง"""
	if not is_active:
		return
	
	# ถ้าชนผนัง (StaticBody2D)
	if body is StaticBody2D:
		collision_count += 1
		print("[MazeMinigame] ชนผนัง! (%d/%d)" % [collision_count, max_collisions])
		_update_ui()
		
		# เช็คว่าชนครบหรือยัง
		if collision_count >= max_collisions:
			_restart_game()

func _restart_game():
	"""เริ่มเกมใหม่ทันที"""
	print("[MazeMinigame] เริ่มเกมใหม่!")
	is_dragging = false
	collision_count = 0
	_reset_item()
	_update_ui()

func _update_ui():
	"""อัปเดต UI"""
	status_label.text = "การชน: %d/%d" % [collision_count, max_collisions]
	
	if collision_count >= max_collisions:
		status_label.modulate = Color.RED
	elif collision_count > 0:
		status_label.modulate = Color.YELLOW
	else:
		status_label.modulate = Color.WHITE

func _process(_delta):
	if not is_active:
		return
	
	# เช็คว่าไอเท็มออกจากเขาวงกตแล้วหรือยัง (นอก MazeContainer)
	if item and not is_dragging:
		var item_pos = item.global_position
		var maze_pos = maze_container.global_position
		var distance = item_pos.distance_to(maze_pos)
		
		# ถ้าห่างจากจุดกลางเขาวงกตมากกว่า 400 พิกเซล = ออกจากเขาวงกต
		if distance > 400:
			_complete_minigame()

func _complete_minigame():
	"""จบเกม - สำเร็จ!"""
	if not is_active:
		return
	
	print("[MazeMinigame] สำเร็จ! หยิบไอเท็มออกมาได้โดยไม่ชนเกิน!")
	is_active = false
	is_dragging = false
	
	# แสดงข้อความสำเร็จ
	instruction_label.text = "สำเร็จ! 🎉"
	instruction_label.modulate = Color.GREEN
	
	await get_tree().create_timer(1.5).timeout
	
	# ปลดล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	completed.emit()
	print("[MazeMinigame] ส่งสัญญาณ 'completed'")
