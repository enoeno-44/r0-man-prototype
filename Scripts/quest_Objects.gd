extends Area2D

@export var object_id: String = "trash_a"
@export var quest_index: int = 0
@export var required_qte_count: int = 3
@export var completed_texture: Texture2D

@onready var label = $Label
@onready var progress_label = $ProgressLabel
@onready var object_sprite = $Sprite2D

var player_in_range: bool = false

func _ready():
	# เพิ่มเข้า group เพื่อให้ลูกศรหาเจอ
	add_to_group("quest_area")
	
	# ตรวจสอบว่า quest นี้เป็นของวันนี้หรือไม่
	_check_if_active_today()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	QTEManager.register_qte(object_id, required_qte_count)
	
	QTEManager.qte_success.connect(_on_qte_success)
	QTEManager.qte_failed.connect(_on_qte_failed)
	QTEManager.qte_fully_completed.connect(_on_qte_fully_completed)
	
	label.hide()
	_update_progress_display()
	
	if QTEManager.is_fully_completed(object_id):
		_mark_as_completed()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_try_interact()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if not QTEManager.is_fully_completed(object_id):
			label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.hide()

func _try_interact():
	if QTEManager.is_fully_completed(object_id):
		print("ทำเควสนี้เสร็จแล้ว!")
		return
	label.hide()
	QTEManager.start_qte(object_id)

func _on_qte_success(completed_id: String, current: int, required: int):
	if completed_id == object_id:
		print("สำเร็จ! (%d/%d)" % [current, required])
		_update_progress_display()
		
		if current < required and player_in_range:
			await get_tree().create_timer(0.5).timeout
			if player_in_range and not QTEManager.is_fully_completed(object_id) and not QTEManager.is_active():
				label.show()

func _on_qte_failed(failed_id: String, current: int, required: int):
	if failed_id == object_id:
		print("ล้มเหลว! ลองใหม่ (%d/%d)" % [current, required])
		if player_in_range:
			await get_tree().create_timer(0.5).timeout
			if player_in_range and not QTEManager.is_fully_completed(object_id) and not QTEManager.is_active():
				label.show()

func _on_qte_fully_completed(completed_id: String):
	if completed_id == object_id:
		_mark_as_completed()
		QuestManager.complete_quest(quest_index)

func _update_progress_display():
	var progress = QTEManager.get_progress(object_id)
	if progress_label:
		progress_label.text = "%d/%d" % [progress.current, progress.required]

func _mark_as_completed():
	modulate = Color(1, 1, 1)
	label.text = "เสร็จสิ้น!"
	label.hide() 
	
	if progress_label:
		progress_label.text = "เสร็จสิ้น!"
		
	if object_sprite and completed_texture:
		object_sprite.texture = completed_texture

func _check_if_active_today():
	"""ตรวจสอบว่า quest นี้เป็นของวันนี้หรือไม่"""
	var today_quests = DayManager.get_daily_quests()
	
	if quest_index not in today_quests:
		# ถ้าไม่ใช่ quest ของวันนี้ ให้ซ่อน
		visible = false
		set_process(false)
	else:
		visible = true
		set_process(true)
