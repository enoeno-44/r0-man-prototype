# quest_Objects.gd
extends Area2D

@export var quest_id: String = "trash_a"
@export var quest_day: int = 1
@export var required_qte_count: int = 3
@export var completed_texture: Texture2D

@onready var label = $Label
@onready var object_sprite = $Sprite2D

var player_in_range: bool = false
var is_locked: bool = false
var permanently_locked: bool = false

func _ready():
	add_to_group("quest_area")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	QTEManager.register_qte(quest_id, required_qte_count)
	QTEManager.qte_success.connect(_on_qte_success)
	QTEManager.qte_failed.connect(_on_qte_failed)
	QTEManager.qte_fully_completed.connect(_on_qte_fully_completed)
	QTEManager.qte_ended.connect(_on_qte_ended)
	DayManager.day_changed.connect(_on_day_changed)
	
	label.hide()
	
	await get_tree().process_frame
	_update_visibility()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact") and not is_locked and not permanently_locked:
		_try_interact()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if _is_active() and not QTEManager.is_fully_completed(quest_id) and not is_locked and not permanently_locked:
			label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.hide()

func _try_interact():
	if not _is_active():
		return
	
	if QTEManager.is_fully_completed(quest_id):
		return
	
	if is_locked or permanently_locked:
		return
	
	label.hide()
	is_locked = true
	QTEManager.start_qte(quest_id)

func _on_qte_success(completed_id: String, current: int, required: int):
	if completed_id != quest_id:
		return
	
	if current < required and player_in_range:
		await get_tree().create_timer(0.5).timeout
		if player_in_range and not QTEManager.is_fully_completed(quest_id) and not QTEManager.is_active():
			label.show()

func _on_qte_failed(failed_id: String, current: int, required: int):
	if failed_id != quest_id:
		return
	
	if player_in_range:
		await get_tree().create_timer(0.5).timeout
		if player_in_range and not QTEManager.is_fully_completed(quest_id) and not QTEManager.is_active():
			label.show()

func _on_qte_ended(ended_id: String, was_successful: bool):
	if ended_id != quest_id:
		return
	
	if not permanently_locked:
		is_locked = false

func force_lock():
	permanently_locked = true
	is_locked = true
	label.hide()

func get_quest_id() -> String:
	return quest_id

func _on_qte_fully_completed(completed_id: String):
	if completed_id == quest_id:
		_mark_as_completed()
		QuestManager.complete_quest(quest_id)

func _mark_as_completed():
	modulate = Color.WHITE
	label.text = "เสร็จสิ้น"
	label.hide()
	is_locked = true
	permanently_locked = true
	
	if object_sprite and completed_texture:
		object_sprite.texture = completed_texture

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
			QTEManager.reset_progress(quest_id)
			is_locked = false
		else:
			_mark_as_completed()

func _on_day_changed(_new_day: int, _date_text: String):
	await get_tree().create_timer(0.1).timeout
	_update_visibility()
