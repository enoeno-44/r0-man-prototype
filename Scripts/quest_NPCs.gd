# สคริปต์สำหรับ NPC quest ที่มีบทสนทนา (รองรับทั้งแบบมี/ไม่มีมินิเกม)
extends Area2D

@export var quest_id: String = "npc_grandma_day1"
@export var quest_day: int = 1
@export var dialogue_resource: String = "res://dialogues/grandma_day1.dialogue"
@export var dialogue_start: String = "start"

# มินิเกม (optional)
@export var minigame_scene: PackedScene
@export var has_minigame: bool = true

# ไอเทม (optional)
@export var reward_item_name: String = ""
@export var reward_item_icon: Texture2D

@onready var label = $Label
@onready var npc_sprite = $CharacterBody2D/Sprite2D

var player_in_range: bool = false
var is_talking: bool = false
var minigame_instance = null

func _ready():
	add_to_group("quest_area")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayManager.day_changed.connect(_on_day_changed)
	
	label.hide()
	
	await get_tree().process_frame
	_update_visibility()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_try_interact()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if _is_active() and not QuestManager.is_quest_done(quest_id):
			label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.hide()

func _try_interact():
	if is_talking or not _is_active():
		return
	
	if QuestManager.is_quest_done(quest_id):
		print("[NPCQuest] คุยกับ NPC นี้เสร็จแล้ว")
		return
	
	label.hide()
	is_talking = true
	_start_dialogue_flow()

func _start_dialogue_flow():
	"""เริ่มขั้นตอนการสนทนาทั้งหมด"""
	print("[NPCQuest] === เริ่ม Dialogue Flow ===")
	
	_freeze_player(true)
	
	# 1. เล่นบทสนทนาส่วนแรก
	print("[NPCQuest] เล่นบทสนทนาส่วนแรก")
	await _play_dialogue(dialogue_start)
	print("[NPCQuest] บทสนทนาส่วนแรกจบ")
	
	# 2. ถ้ามีมินิเกม
	if has_minigame:
		print("[NPCQuest] เริ่มมินิเกม...")
		await _handle_minigame()
		print("[NPCQuest] มินิเกมจบ")
		
		# 3. เล่นบทสนทนาส่วนท้าย
		print("[NPCQuest] เล่นบทสนทนาหลังมินิเกม")
		await _play_dialogue("after_minigame")
		print("[NPCQuest] บทสนทนาหลังมินิเกมจบ")
	
	# 4. จบ quest
	_complete_quest()

func _play_dialogue(start_title: String):
	"""เล่น dialogue และรอจนจบ"""
	print("[NPCQuest] กำลังเล่น dialogue: " + start_title)
	
	var dialogue_resource_loaded = load(dialogue_resource)
	DialogueManager.show_dialogue_balloon(dialogue_resource_loaded, start_title)
	
	# รอให้ dialogue จบ
	await DialogueManager.dialogue_ended
	print("[NPCQuest] ✓ Dialogue '%s' จบแล้ว" % start_title)
	
	await get_tree().create_timer(0.3).timeout

func _handle_minigame():
	"""จัดการมินิเกม"""
	if not minigame_scene:
		push_error("[NPCQuest] ไม่ได้กำหนด minigame_scene")
		return
	
	print("[NPCQuest] === เริ่มมินิเกม ===")
	
	# รอให้ dialogue ปิดสนิท
	await get_tree().create_timer(0.5).timeout
	
	# สร้างมินิเกม
	minigame_instance = minigame_scene.instantiate()
	get_tree().root.add_child(minigame_instance)
	
	# เริ่มมินิเกม
	if minigame_instance.has_method("start_minigame"):
		minigame_instance.start_minigame()
	
	# รอให้มินิเกมจบ
	if minigame_instance.has_signal("completed"):
		await minigame_instance.completed
		print("[NPCQuest] ✓ มินิเกมเสร็จสมบูรณ์")
	else:
		push_error("[NPCQuest] มินิเกมไม่มี signal 'completed'")
		await get_tree().create_timer(3.0).timeout
	
	# ลบมินิเกม
	if minigame_instance:
		minigame_instance.queue_free()
		minigame_instance = null
	
	await get_tree().create_timer(0.3).timeout

func _complete_quest():
	"""จบ quest"""
	print("[NPCQuest] === Quest เสร็จสิ้น ===")
	
	# ปลดล็อคผู้เล่น
	_freeze_player(false)
	
	# ให้ไอเทม (ถ้ามี)
	if reward_item_name != "":
		_give_reward_item()
	
	# เสร็จสิ้น quest
	_mark_as_completed()
	is_talking = false
	QuestManager.complete_quest(quest_id)

func _give_reward_item():
	"""ให้ไอเทม"""
	print("[NPCQuest] ได้รับไอเทม: " + reward_item_name)
	
	if has_node("/root/ItemManager"):
		ItemManager.add_item(reward_item_name, reward_item_icon)
	else:
		print("[NPCQuest] ไม่พบ ItemManager!")

func _freeze_player(freeze: bool):
	"""หยุด/ปลดล็อคผู้เล่น"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)

func _mark_as_completed():
	"""ทำเครื่องหมายว่าเสร็จแล้ว"""
	modulate = Color(0.7, 0.7, 0.7)
	label.text = "เสร็จสิ้น"
	label.hide()

func _is_active() -> bool:
	return quest_day == DayManager.get_current_day()

func _update_visibility():
	var is_today = _is_active()
	visible = is_today
	set_process(is_today)
	monitoring = is_today
	monitorable = is_today
	
	if is_today:
		if not QuestManager.is_quest_done(quest_id):
			print("[NPCQuest] %s เปิดใช้งาน" % quest_id)
		else:
			_mark_as_completed()
			print("[NPCQuest] %s เสร็จแล้ว" % quest_id)
	else:
		print("[NPCQuest] %s ปิดใช้งาน" % quest_id)

func _on_day_changed(_new_day: int, _date_text: String):
	await get_tree().create_timer(0.1).timeout
	_update_visibility()
