# quest_Objects.gd
extends Area2D

@export var quest_id: String = "trash_a"
@export var quest_day: int = 1
@export var required_qte_count: int = 3
@export var completed_texture: Texture2D
@export var disappear_when_completed: bool = false
@export var disappear_after_day: bool = false

@onready var label = $Label
@onready var object_sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var static_body = $StaticBody2D

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
	if not _is_active() or QTEManager.is_fully_completed(quest_id) or is_locked or permanently_locked:
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
		
		if disappear_when_completed:
			_disappear_object()

func _mark_as_completed():
	modulate = Color.WHITE
	label.text = "เสร็จสิ้น"
	label.hide()
	is_locked = true
	permanently_locked = true
	
	if object_sprite and completed_texture and not disappear_when_completed:
		object_sprite.texture = completed_texture

func _is_active() -> bool:
	return quest_day == DayManager.get_current_day()

# อัปเดตการมองเห็นและ collision ตามวันและสถานะ
func _update_visibility():
	var is_today = _is_active()
	var is_completed = QuestManager.is_quest_done(quest_id)
	
	if is_completed and disappear_when_completed:
		_disappear_object()
		return
	
	if not is_today and disappear_after_day and not is_completed:
		_disappear_object()
		return
	
	visible = is_today
	set_process(is_today)
	monitoring = is_today
	monitorable = is_today
	
	if collision_shape:
		collision_shape.set_deferred("disabled", not is_today)
	
	if static_body:
		static_body.set_deferred("process_mode", Node.PROCESS_MODE_INHERIT if is_today else Node.PROCESS_MODE_DISABLED)
		for child in static_body.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", not is_today)
	
	if is_today:
		if not is_completed:
			QTEManager.reset_progress(quest_id)
			is_locked = false
		else:
			if disappear_when_completed:
				_disappear_object()
			else:
				_mark_as_completed()

func _on_day_changed(_new_day: int, _date_text: String):
	await get_tree().create_timer(0.1).timeout
	_update_visibility()

# ทำให้วัตถุหายไปแบบค่อยๆ หรือทันที
func _disappear_object():
	visible = false
	set_process(false)
	monitoring = false
	monitorable = false
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	if static_body:
		static_body.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
		for child in static_body.get_children():
			if child is CollisionShape2D or child is CollisionPolygon2D:
				child.set_deferred("disabled", true)
