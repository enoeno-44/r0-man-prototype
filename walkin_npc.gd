# NPC ที่เดินไปมาและแสดงข้อความเมื่อผู้เล่นเข้าใกล้
extends CharacterBody2D

# === การเคลื่อนที่ ===
@export var waypoints: Array[Vector2] = []  # จุดที่ NPC จะเดินไป
@export var move_speed: float = 50.0
@export var wait_time_at_waypoint: float = 2.0  # เวลารอที่แต่ละจุด
@export var stop_at_end: bool = true  # หยุดที่จุดสุดท้าย
@export var initial_wait_time: float = 0.0  # รอก่อนเริ่มเดิน (วินาที)

# === ข้อความบนหัว ===
@export var greeting_text: String = "สวัสดี เจ้าหุ่น"
@export var detection_radius: float = 100.0  # ระยะที่ตรวจจับผู้เล่น
@export var message_duration: float = 3.0  # ข้อความแสดงนานเท่าไร

# === Animation (ถ้ามี) ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# Label สำหรับแสดงข้อความ
var message_label: Label

# ตัวแปรสำหรับการเคลื่อนที่
var current_waypoint_index: int = 0
var is_waiting: bool = false
var is_moving: bool = false
var has_shown_message: bool = false  # แสดงข้อความครั้งเดียว
var player_in_range: bool = false

# ตัวแปรสำหรับ Animation
var last_direction: Vector2 = Vector2.DOWN

func _ready():
	_create_detection_area()
	_create_message_label()
	
	# เริ่มเคลื่อนที่ถ้ามี waypoints
	if waypoints.size() > 0:
		if initial_wait_time > 0:
			print("[NPC] รอ %.1f วินาทีก่อนเริ่มเดิน" % initial_wait_time)
			await get_tree().create_timer(initial_wait_time).timeout
		
		is_moving = true
		print("[NPC] เริ่มเคลื่อนที่ จำนวนจุด: %d" % waypoints.size())
	else:
		print("[NPC] ⚠ ไม่มี waypoints กำหนด!")
	
	# Test: แสดงข้อความทันทีเพื่อทดสอบ (ลบออกได้ถ้าไม่ต้องการ)
	print("[NPC] ข้อความที่จะแสดง: '%s'" % greeting_text)
	print("[NPC] ตำแหน่ง Label: %s" % str(message_label.global_position))
	print("[NPC] Label visible: %s" % message_label.visible)

func _create_detection_area():
	"""สร้าง Area2D สำหรับตรวจจับผู้เล่น"""
	var detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	detection_area.collision_layer = 0  # ไม่อยู่ใน layer ใดๆ
	detection_area.collision_mask = 2   # ตรวจจับเฉพาะ layer 2 (Player)
	add_child(detection_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = detection_radius
	collision_shape.shape = circle
	detection_area.add_child(collision_shape)
	
	# เชื่อมสัญญาณ
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	
	print("[NPC] สร้าง Detection Area (รัศมี: %.1f, Mask: %d)" % [detection_radius, detection_area.collision_mask])

func _create_message_label():
	"""สร้าง Label สำหรับแสดงข้อความบนหัว"""
	message_label = Label.new()
	message_label.name = "MessageLabel"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# ตกแต่ง Label
	message_label.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_constant_override("outline_size", 6)
	message_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	message_label.add_theme_color_override("font_color", Color(1, 1, 0.8))
	
	# วางตำแหน่งบนหัว NPC
	message_label.position = Vector2(-100, -70)  # ปรับตามขนาด sprite
	message_label.custom_minimum_size = Vector2(200, 30)
	
	add_child(message_label)
	message_label.hide()
	message_label.z_index = 100  # ให้อยู่ด้านหน้าสุด
	
	print("[NPC] สร้าง Message Label")

func _physics_process(delta):
	if waypoints.size() == 0 or not is_moving or is_waiting:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	var target = waypoints[current_waypoint_index]
	var direction = (target - global_position).normalized()
	
	# เช็คว่าถึงจุดหมายหรือยัง
	if global_position.distance_to(target) < 5:
		_reach_waypoint()
		return
	
	# เคลื่อนที่ไปยังจุดหมาย
	velocity = direction * move_speed
	last_direction = direction
	
	_play_walk_animation(direction)
	move_and_slide()

func _reach_waypoint():
	"""เมื่อถึงจุดหมาย"""
	print("[NPC] ถึงจุดที่ %d" % current_waypoint_index)
	
	is_waiting = true
	velocity = Vector2.ZERO
	_play_idle_animation()
	
	# รอที่จุดนี้
	await get_tree().create_timer(wait_time_at_waypoint).timeout
	
	# ไปจุดถัดไป
	current_waypoint_index += 1
	
	# เช็คว่าถึงจุดสุดท้ายหรือยัง
	if current_waypoint_index >= waypoints.size():
		if stop_at_end:
			print("[NPC] ถึงจุดสุดท้ายแล้ว - หยุดเคลื่อนที่")
			is_moving = false
			is_waiting = false
			_play_idle_animation()
			return
		else:
			# วนกลับไปจุดแรก
			current_waypoint_index = 0
			print("[NPC] วนกลับไปจุดแรก")
	
	is_waiting = false

func _on_body_entered(body):
	"""เมื่อมีวัตถุเข้ามาในรัศมี"""
	print("[NPC] ตรวจพบ body: %s (group: %s)" % [body.name, body.get_groups()])
	
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		print("[NPC] ✓ ผู้เล่นเข้ามาใกล้!")
		
		if not has_shown_message:
			_show_message()
		else:
			print("[NPC] ⚠ ข้อความแสดงไปแล้ว")

func _on_body_exited(body):
	"""เมื่อวัตถุออกจากรัศมี"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false
		print("[NPC] ผู้เล่นออกไป")

func _show_message():
	"""แสดงข้อความบนหัว"""
	if has_shown_message:
		print("[NPC] ⚠ ข้อความแสดงไปแล้ว")
		return
	
	if greeting_text == "":
		print("[NPC] ⚠ ไม่มีข้อความกำหนด!")
		return
	
	has_shown_message = true
	print("[NPC] 🗨 กำลังแสดงข้อความ: '%s'" % greeting_text)
	
	message_label.text = greeting_text
	message_label.visible = true
	print("[NPC] Label visible: %s, text: '%s'" % [message_label.visible, message_label.text])
	
	# Fade in
	message_label.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 1.0, 0.3)
	await tween.finished
	
	print("[NPC] ✓ Fade in เสร็จ (alpha: %.2f)" % message_label.modulate.a)
	
	# รอแล้ว Fade out
	await get_tree().create_timer(message_duration).timeout
	
	print("[NPC] กำลัง Fade out...")
	tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	message_label.hide()
	print("[NPC] ✓ ซ่อนข้อความแล้ว")

# ========================================
# Animation Functions (ถ้ามี AnimatedSprite2D)
# ========================================

func _play_walk_animation(dir: Vector2):
	"""เล่น animation เดิน"""
	if not sprite or not sprite.sprite_frames:
		return
	
	var frames = sprite.sprite_frames
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0 and frames.has_animation("walk_right"):
			sprite.play("walk_right")
		elif dir.x < 0 and frames.has_animation("walk_left"):
			sprite.play("walk_left")
	else:
		if dir.y > 0 and frames.has_animation("walk_down"):
			sprite.play("walk_down")
		elif dir.y < 0 and frames.has_animation("walk_up"):
			sprite.play("walk_up")

func _play_idle_animation():
	"""เล่น animation หยุด"""
	if not sprite or not sprite.sprite_frames:
		return
	
	var frames = sprite.sprite_frames
	
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0 and frames.has_animation("idle_right"):
			sprite.play("idle_right")
		elif last_direction.x < 0 and frames.has_animation("idle_left"):
			sprite.play("idle_left")
	else:
		if last_direction.y > 0 and frames.has_animation("idle_down"):
			sprite.play("idle_down")
		elif last_direction.y < 0 and frames.has_animation("idle_up"):
			sprite.play("idle_up")

# ========================================
# Helper Functions
# ========================================

func set_waypoints(points: Array[Vector2]):
	"""กำหนดเส้นทางใหม่"""
	waypoints = points
	current_waypoint_index = 0
	is_moving = waypoints.size() > 0
	print("[NPC] ตั้งค่า waypoints ใหม่: %d จุด" % waypoints.size())

func pause_movement():
	"""หยุดการเคลื่อนที่ชั่วคราว"""
	is_moving = false
	print("[NPC] หยุดการเคลื่อนที่")

func resume_movement():
	"""กลับมาเคลื่อนที่ต่อ"""
	if waypoints.size() > 0:
		is_moving = true
		print("[NPC] เริ่มเคลื่อนที่ต่อ")

func reset_message():
	"""รีเซ็ตให้แสดงข้อความได้อีกครั้ง"""
	has_shown_message = false
	print("[NPC] รีเซ็ตข้อความ")
