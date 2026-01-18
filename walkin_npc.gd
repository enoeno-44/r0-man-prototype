# NPC ที่เดินไปมา + แสดง Dialogue + ใช้สำหรับจบเกม
extends CharacterBody2D

# === การเคลื่อนที่ ===
@export var waypoints: Array[Vector2] = []
@export var move_speed: float = 50.0
@export var wait_time_at_waypoint: float = 2.0
@export var stop_at_end: bool = true
@export var initial_wait_time: float = 0.0

# === Dialogue ===
@export_group("Dialogue Settings")
@export var has_dialogue: bool = false
@export var dialogue_resource: String = ""
@export var dialogue_start: String = "start"
@export var detection_radius: float = 100.0

# === Quest Trigger (สำหรับจบเกม) ===
@export_group("Quest Trigger")
@export var wait_for_quest_start: bool = false  # ปรากฏเมื่อเริ่ม Quest
@export var trigger_quest_id: String = ""  # เช่น "trash_17"

# === End Game ===
@export_group("End Game")
@export var is_ending_npc: bool = false
@export var ending_delay: float = 0.5  # ดีเลย์หลัง Dialogue จบ

# === Animation ===
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

# ตัวแปรภายใน
var current_waypoint_index: int = 0
var is_waiting: bool = false
var is_moving: bool = false
var player_in_range: bool = false
var has_talked: bool = false
var is_talking: bool = false
var waiting_for_quest: bool = false
var qte_has_ended: bool = false
var last_direction: Vector2 = Vector2.DOWN

# Detection Area
var detection_area: Area2D

func _ready():
	# ถ้าต้องรอ Quest เริ่ม
	if wait_for_quest_start and trigger_quest_id != "":
		visible = false
		set_physics_process(false)
		waiting_for_quest = true
		qte_has_ended = false
		
		# เชื่อมต่อ signal ของ QTEManager
		if has_node("/root/QTEManager"):
			QTEManager.qte_started.connect(_on_qte_started)
			QTEManager.qte_ended.connect(_on_qte_ended)
			print("[WalkingNPC] ✓ เชื่อมต่อ Signal สำเร็จ")
		else:
			push_error("[WalkingNPC] ไม่พบ QTEManager!")
		
		print("[WalkingNPC] ซ่อนตัว - รอ Quest เริ่ม: %s" % trigger_quest_id)
		return
	
	_setup()

func _on_qte_started(quest_id: String):
	"""เมื่อผู้เล่นเริ่มทำ QTE ของ Quest นี้"""
	if not waiting_for_quest or quest_id != trigger_quest_id:
		return
	
	print("[WalkingNPC] ✓ ตรวจพบ QTE เริ่ม: %s - ปรากฏตัว!" % quest_id)
	
	# ตัดการเชื่อมต่อ qte_started
	if QTEManager.qte_started.is_connected(_on_qte_started):
		QTEManager.qte_started.disconnect(_on_qte_started)
	
	waiting_for_quest = false
	qte_has_ended = false
	visible = true
	set_physics_process(true)
	_setup()

func _on_qte_ended(quest_id: String, was_successful: bool):
	"""เมื่อผู้เล่นออกจาก QTE (ผ่านหรือไม่ผ่านก็ได้)"""
	if quest_id != trigger_quest_id:
		return
	
	print("[WalkingNPC] ✓✓✓ QTE '%s' จบแล้ว! (สำเร็จ: %s)" % [quest_id, was_successful])
	print("[WalkingNPC] สถานะ: moving=%s, in_range=%s, has_talked=%s" % [is_moving, player_in_range, has_talked])
	
	# ตัดการเชื่อมต่อ
	if QTEManager.qte_ended.is_connected(_on_qte_ended):
		QTEManager.qte_ended.disconnect(_on_qte_ended)
	
	qte_has_ended = true
	
	# ลองเริ่ม Dialogue ทันที
	_try_start_dialogue()

func _try_start_dialogue():
	"""พยายามเริ่ม Dialogue ถ้าเงื่อนไขครบ"""
	print("[WalkingNPC] _try_start_dialogue: moving=%s, qte_ended=%s, in_range=%s, talked=%s" % [is_moving, qte_has_ended, player_in_range, has_talked])
	
	# ตรวจสอบเงื่อนไข
	if is_moving:
		print("[WalkingNPC] ❌ NPC ยังเดินอยู่")
		return
	
	if not qte_has_ended:
		print("[WalkingNPC] ❌ QTE ยังไม่จบ")
		return
	
	if has_talked:
		print("[WalkingNPC] ❌ พูดไปแล้ว")
		return
	
	if not has_dialogue:
		print("[WalkingNPC] ❌ ไม่มี dialogue")
		return
	
	if not player_in_range:
		print("[WalkingNPC] ❌ ผู้เล่นยังไม่เข้ามาใกล้")
		return
	
	# ทุกเงื่อนไขผ่าน!
	print("[WalkingNPC] ✓✓✓ ครบทุกเงื่อนไข! เริ่ม Dialogue!")
	call_deferred("_start_dialogue_delayed")

func _start_dialogue_delayed():
	"""เริ่ม Dialogue แบบ Delayed"""
	# ⭐ เพิ่มดีเลย์เพื่อให้แน่ใจว่า QTE UI หายไปแล้ว
	await get_tree().create_timer(0.8).timeout
	_trigger_dialogue()

func _setup():
	"""ตั้งค่าเริ่มต้น"""
	if has_dialogue:
		_create_detection_area()
	
	# เริ่มเคลื่อนที่
	if waypoints.size() > 0:
		if initial_wait_time > 0:
			await get_tree().create_timer(initial_wait_time).timeout
		is_moving = true
		print("[WalkingNPC] เริ่มเดิน - จุด: %d" % waypoints.size())

func _create_detection_area():
	"""สร้าง Area2D สำหรับตรวจจับผู้เล่น"""
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2
	add_child(detection_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = detection_radius
	collision_shape.shape = circle
	detection_area.add_child(collision_shape)
	
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _physics_process(delta):
	if waypoints.size() == 0 or not is_moving or is_waiting:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	var target = waypoints[current_waypoint_index]
	var direction = (target - global_position).normalized()
	
	if global_position.distance_to(target) < 5:
		_reach_waypoint()
		return
	
	velocity = direction * move_speed
	last_direction = direction
	_play_walk_animation(direction)
	move_and_slide()

func _reach_waypoint():
	"""เมื่อถึงจุดหมาย"""
	print("[WalkingNPC] ถึงจุดที่ %d" % current_waypoint_index)
	
	is_waiting = true
	velocity = Vector2.ZERO
	_play_idle_animation()
	
	current_waypoint_index += 1
	
	# ถ้าถึงจุดสุดท้าย
	if current_waypoint_index >= waypoints.size():
		if stop_at_end:
			print("[WalkingNPC] ✓ ถึงจุดสุดท้าย - หยุดเดิน")
			is_moving = false
			is_waiting = false
			_play_idle_animation()
			
			# ⭐ ปิด QTE ที่กำลังเล่นอยู่ทันที
			await _force_close_qte()
			
			# ลองเริ่ม Dialogue
			_try_start_dialogue()
			return
		else:
			current_waypoint_index = 0
	
	# รอที่จุดนี้
	await get_tree().create_timer(wait_time_at_waypoint).timeout
	is_waiting = false

func _force_close_qte():
	"""บังคับปิด QTE ถ้ากำลังเล่นอยู่"""
	if not has_node("/root/QTEManager"):
		return
	
	# ⭐ ล็อควัตถุทั้งหมดที่เกี่ยวข้องกับ quest นี้
	_lock_all_quest_objects()
	
	if QTEManager.is_active():
		print("[WalkingNPC] ⚠️ กำลังปิด QTE ที่ผู้เล่นทำอยู่...")
		QTEManager.force_end_qte()
		qte_has_ended = true
		# ⭐ รอให้ UI หายไปจริงๆ
		await get_tree().create_timer(0.3).timeout
		print("[WalkingNPC] ✓ QTE ปิดเรียบร้อยแล้ว")

func _lock_all_quest_objects():
	"""ล็อควัตถุทั้งหมดที่มี quest_id ตรงกับ trigger_quest_id"""
	if trigger_quest_id == "":
		return
	
	var quest_objects = get_tree().get_nodes_in_group("quest_area")
	for obj in quest_objects:
		if obj.has_method("get_quest_id") and obj.get_quest_id() == trigger_quest_id:
			obj.force_lock()
			print("[WalkingNPC] ล็อควัตถุ: %s" % trigger_quest_id)

func _on_body_entered(body):
	"""ผู้เล่นเข้ามาใกล้"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		print("[WalkingNPC] ✓ ผู้เล่นเข้ามาใกล้")
		
		# ลองเริ่ม Dialogue
		_try_start_dialogue()

func _on_body_exited(body):
	"""ผู้เล่นออกไป"""
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false
		print("[WalkingNPC] ผู้เล่นออกไป")

func _trigger_dialogue():
	"""เริ่มบทสนทนา"""
	if is_talking or has_talked:
		print("[WalkingNPC] ❌ กำลังพูดอยู่หรือพูดไปแล้ว")
		return
	
	if dialogue_resource == "":
		push_error("[WalkingNPC] ไม่ได้กำหนด dialogue_resource!")
		return
	
	print("[WalkingNPC] === เริ่ม Dialogue ===")
	is_talking = true
	has_talked = true
	
	# หยุดการเคลื่อนที่
	is_moving = false
	velocity = Vector2.ZERO
	_play_idle_animation()
	
	# หยุดผู้เล่น
	_freeze_player(true)
	
	# เล่น Dialogue
	var dialogue_resource_loaded = load(dialogue_resource)
	if dialogue_resource_loaded:
		DialogueManager.show_dialogue_balloon(dialogue_resource_loaded, dialogue_start)
		await DialogueManager.dialogue_ended
		print("[WalkingNPC] ✓ Dialogue จบ")
	else:
		push_error("[WalkingNPC] โหลด dialogue_resource ไม่สำเร็จ: " + dialogue_resource)
	
	# ปลดล็อคผู้เล่น (ถ้าไม่ใช่ Ending NPC)
	if not is_ending_npc:
		_freeze_player(false)
	
	is_talking = false
	
	# ถ้าเป็น Ending NPC
	if is_ending_npc:
		print("[WalkingNPC] === เริ่มฉากจบเกม ===")
		await get_tree().create_timer(ending_delay).timeout
		_trigger_end_game()

func _trigger_end_game():
	"""จบเกม - เรียก EndGameManager"""
	if has_node("/root/EndGameManager"):
		EndGameManager.start_ending()
	else:
		push_error("[WalkingNPC] ไม่พบ EndGameManager!")

func _freeze_player(freeze: bool):
	"""หยุด/ปลดล็อคผู้เล่น"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)

# ========================================
# Animation Functions
# ========================================

func _play_walk_animation(dir: Vector2):
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
