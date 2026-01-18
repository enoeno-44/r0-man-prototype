# Walking NPC with dialogue and end game trigger
extends CharacterBody2D

@export var waypoints: Array[Vector2] = []
@export var move_speed: float = 50.0
@export var wait_time_at_waypoint: float = 2.0
@export var stop_at_end: bool = true
@export var initial_wait_time: float = 0.0

@export_group("Dialogue Settings")
@export var has_dialogue: bool = false
@export var dialogue_resource: String = ""
@export var dialogue_start: String = "start"
@export var detection_radius: float = 100.0

@export_group("Quest Trigger")
@export var wait_for_quest_start: bool = false
@export var trigger_quest_id: String = ""

@export_group("End Game")
@export var is_ending_npc: bool = false
@export var ending_delay: float = 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

var current_waypoint_index: int = 0
var is_waiting: bool = false
var is_moving: bool = false
var player_in_range: bool = false
var has_talked: bool = false
var is_talking: bool = false
var waiting_for_quest: bool = false
var qte_has_ended: bool = false
var last_direction: Vector2 = Vector2.DOWN

var detection_area: Area2D

func _ready():
	if wait_for_quest_start and trigger_quest_id != "":
		visible = false
		set_physics_process(false)
		waiting_for_quest = true
		qte_has_ended = false
		
		if has_node("/root/QTEManager"):
			QTEManager.qte_started.connect(_on_qte_started)
			QTEManager.qte_ended.connect(_on_qte_ended)
		
		return
	
	_setup()

func _on_qte_started(quest_id: String):
	if not waiting_for_quest or quest_id != trigger_quest_id:
		return
	
	if QTEManager.qte_started.is_connected(_on_qte_started):
		QTEManager.qte_started.disconnect(_on_qte_started)
	
	waiting_for_quest = false
	qte_has_ended = false
	visible = true
	set_physics_process(true)
	_setup()

func _on_qte_ended(quest_id: String, was_successful: bool):
	if quest_id != trigger_quest_id:
		return
	
	if QTEManager.qte_ended.is_connected(_on_qte_ended):
		QTEManager.qte_ended.disconnect(_on_qte_ended)
	
	qte_has_ended = true
	_try_start_dialogue()

func _try_start_dialogue():
	if is_moving:
		return
	
	if not qte_has_ended:
		return
	
	if has_talked:
		return
	
	if not has_dialogue:
		return
	
	if not player_in_range:
		return
	
	call_deferred("_start_dialogue_delayed")

func _start_dialogue_delayed():
	await get_tree().create_timer(0.8).timeout
	_trigger_dialogue()

func _setup():
	if has_dialogue:
		_create_detection_area()
	
	if waypoints.size() > 0:
		if initial_wait_time > 0:
			await get_tree().create_timer(initial_wait_time).timeout
		is_moving = true

func _create_detection_area():
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
	is_waiting = true
	velocity = Vector2.ZERO
	_play_idle_animation()
	
	current_waypoint_index += 1
	
	if current_waypoint_index >= waypoints.size():
		if stop_at_end:
			is_moving = false
			is_waiting = false
			_play_idle_animation()
			
			await _force_close_qte()
			_try_start_dialogue()
			return
		else:
			current_waypoint_index = 0
	
	await get_tree().create_timer(wait_time_at_waypoint).timeout
	is_waiting = false

func _force_close_qte():
	if not has_node("/root/QTEManager"):
		return
	
	_lock_all_quest_objects()
	
	if QTEManager.is_active():
		QTEManager.force_end_qte()
		qte_has_ended = true
		await get_tree().create_timer(0.3).timeout

func _lock_all_quest_objects():
	if trigger_quest_id == "":
		return
	
	var quest_objects = get_tree().get_nodes_in_group("quest_area")
	for obj in quest_objects:
		if obj.has_method("get_quest_id") and obj.get_quest_id() == trigger_quest_id:
			obj.force_lock()

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = true
		_try_start_dialogue()

func _on_body_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false

func _trigger_dialogue():
	if is_talking or has_talked:
		return
	
	if dialogue_resource == "":
		return
	
	is_talking = true
	has_talked = true
	
	is_moving = false
	velocity = Vector2.ZERO
	_play_idle_animation()
	
	_freeze_player(true)
	
	var dialogue_resource_loaded = load(dialogue_resource)
	if dialogue_resource_loaded:
		DialogueManager.show_dialogue_balloon(dialogue_resource_loaded, dialogue_start)
		await DialogueManager.dialogue_ended
	
	if not is_ending_npc:
		_freeze_player(false)
	
	is_talking = false
	
	if is_ending_npc:
		await get_tree().create_timer(ending_delay).timeout
		_trigger_end_game()

func _trigger_end_game():
	if has_node("/root/EndGameManager"):
		EndGameManager.start_ending()

func _freeze_player(freeze: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)

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
