# สคริปต์สำหรับ NPC quest ที่มีบทสนทนาและมินิเกม
extends Area2D

@export var quest_id: String = "npc_grandma_day1"
@export var quest_day: int = 1
@export var dialogue_resource: String = "res://dialogues/grandma_day1.dialogue"
@export var dialogue_start: String = "start"
@export var minigame_scene: PackedScene

@onready var label = $Label
@onready var npc_sprite = $Sprite2D

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
	_start_dialogue()

func _start_dialogue():
	print("[NPCQuest] เริ่มบทสนทนา: " + dialogue_resource)
	
	# หยุดผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		if player.has_method("set_can_move"):
			player.set_can_move(false)
	
	if not DialogueManager.passed_title.is_connected(_on_dialogue_reached_node):
		DialogueManager.passed_title.connect(_on_dialogue_reached_node)
	
	DialogueManager.show_dialogue_balloon(load(dialogue_resource), dialogue_start)

func _on_dialogue_reached_node(title: String):
	print("[NPCQuest] ไปถึง node: " + title)
	
	if title == "minigame":
		print("[NPCQuest] เริ่มมินิเกม")
		await get_tree().create_timer(0.3).timeout
		_start_minigame()

func _start_minigame():
	if not minigame_scene:
		push_error("[NPCQuest] ไม่ได้กำหนด minigame_scene")
		_continue_dialogue_after_minigame()
		return
	
	minigame_instance = minigame_scene.instantiate()
	get_tree().root.add_child(minigame_instance)
	
	if minigame_instance.has_method("start_minigame"):
		minigame_instance.start_minigame()
	
	await minigame_instance.completed
	
	print("[NPCQuest] มินิเกมเสร็จแล้ว")
	
	minigame_instance.queue_free()
	minigame_instance = null
	
	_continue_dialogue_after_minigame()

func _continue_dialogue_after_minigame():
	print("[NPCQuest] เล่นบทสนทนาต่อ...")
	
	DialogueManager.show_dialogue_balloon(load(dialogue_resource), "end")
	
	await DialogueManager.dialogue_ended
	
	print("[NPCQuest] บทสนทนาจบสมบูรณ์")
	_on_dialogue_finished()

func _on_dialogue_finished():
	# ปลดล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	if DialogueManager.passed_title.is_connected(_on_dialogue_reached_node):
		DialogueManager.passed_title.disconnect(_on_dialogue_reached_node)
	
	_mark_as_completed()
	is_talking = false
	QuestManager.complete_quest(quest_id)

func _mark_as_completed():
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
