# quest_NPCs.gd
extends Area2D

@export var quest_id: String = "npc_grandma_day1"
@export var quest_day: int = 1
@export var dialogue_resource: String = "res://dialogues/grandma_day1.dialogue"
@export var dialogue_start: String = "start"

@export var minigame_scene: PackedScene
@export var has_minigame: bool = true

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
		return
	
	label.hide()
	is_talking = true
	_start_dialogue_flow()

func _start_dialogue_flow():
	_freeze_player(true)
	
	await _play_dialogue(dialogue_start)
	
	if has_minigame:
		await _handle_minigame()
		await _play_dialogue("after_minigame")
	
	_complete_quest()

func _play_dialogue(start_title: String):
	var dialogue_resource_loaded = load(dialogue_resource)
	DialogueManager.show_dialogue_balloon(dialogue_resource_loaded, start_title)
	await DialogueManager.dialogue_ended
	await get_tree().create_timer(0.3).timeout

func _handle_minigame():
	if not minigame_scene:
		return
	
	await get_tree().create_timer(0.5).timeout
	
	minigame_instance = minigame_scene.instantiate()
	get_tree().root.add_child(minigame_instance)
	
	if minigame_instance.has_method("start_minigame"):
		minigame_instance.start_minigame()
	
	if minigame_instance.has_signal("completed"):
		await minigame_instance.completed
	else:
		await get_tree().create_timer(3.0).timeout
		
	_freeze_player(true)
	if minigame_instance:
		minigame_instance.queue_free()
		minigame_instance = null
	
	await get_tree().create_timer(0.3).timeout

func _complete_quest():
	_freeze_player(false)
	
	if reward_item_name != "":
		_give_reward_item()
	
	_mark_as_completed()
	is_talking = false
	QuestManager.complete_quest(quest_id)

func _give_reward_item():
	if has_node("/root/ItemManager"):
		ItemManager.add_item(reward_item_name, reward_item_icon)

func _freeze_player(freeze: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)
		if freeze and player.has_method("force_idle"):
			player.force_idle()

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
			pass
		else:
			_mark_as_completed()

func _on_day_changed(_new_day: int, _date_text: String):
	await get_tree().create_timer(0.1).timeout
	_update_visibility()
