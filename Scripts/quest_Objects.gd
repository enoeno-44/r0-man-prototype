extends Area2D

# ตั้งค่าหลัก
@export var quest_id: String = "trash_a"  # ใช้ quest_id แทน quest_index
@export var quest_day: int = 1  # วันที่ของ quest นี้
@export var required_qte_count: int = 3
@export var completed_texture: Texture2D

@onready var label = $Label
@onready var progress_label = $ProgressLabel
@onready var object_sprite = $Sprite2D

var player_in_range: bool = false

func _ready():
	add_to_group("quest_area")
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# ลงทะเบียน QTE
	QTEManager.register_qte(quest_id, required_qte_count)
	
	# เชื่อมต่อ signals
	QTEManager.qte_success.connect(_on_qte_success)
	QTEManager.qte_failed.connect(_on_qte_failed)
	QTEManager.qte_fully_completed.connect(_on_qte_fully_completed)
	DayManager.day_changed.connect(_on_day_changed)
	
	label.hide()
	_check_if_active_today()
	_update_progress_display()
	
	if QTEManager.is_fully_completed(quest_id):
		_mark_as_completed()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_try_interact()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		if _is_active() and not QTEManager.is_fully_completed(quest_id):
			label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.hide()

func _try_interact():
	if not _is_active():
		print("[QuestObject] Quest นี้ไม่ใช่ของวันนี้")
		return
	
	if QTEManager.is_fully_completed(quest_id):
		print("[QuestObject] ทำเควสนี้เสร็จแล้ว")
		return
	
	label.hide()
	QTEManager.start_qte(quest_id)

func _on_qte_success(completed_id: String, current: int, required: int):
	if completed_id == quest_id:
		print("[QuestObject] สำเร็จ %d/%d" % [current, required])
		_update_progress_display()
		
		if current < required and player_in_range:
			await get_tree().create_timer(0.5).timeout
			if player_in_range and not QTEManager.is_fully_completed(quest_id) and not QTEManager.is_active():
				label.show()

func _on_qte_failed(failed_id: String, current: int, required: int):
	if failed_id == quest_id:
		print("[QuestObject] ล้มเหลว ลองใหม่ %d/%d" % [current, required])
		if player_in_range:
			await get_tree().create_timer(0.5).timeout
			if player_in_range and not QTEManager.is_fully_completed(quest_id) and not QTEManager.is_active():
				label.show()

func _on_qte_fully_completed(completed_id: String):
	if completed_id == quest_id:
		_mark_as_completed()
		QuestManager.complete_quest(quest_id)

func _update_progress_display():
	var progress = QTEManager.get_progress(quest_id)
	if progress_label:
		progress_label.text = "%d/%d" % [progress.current, progress.required]

func _mark_as_completed():
	modulate = Color(1, 1, 1)
	label.text = "เสร็จสิ้น"
	label.hide()
	
	if progress_label:
		progress_label.text = "เสร็จสิ้น"
		
	if object_sprite and completed_texture:
		object_sprite.texture = completed_texture

func _is_active() -> bool:
	"""เช็คว่า quest นี้เป็นของวันนี้หรือไม่"""
	return quest_day == DayManager.get_current_day()

func _check_if_active_today():
	"""ตรวจสอบและอัปเดตสถานะ"""
	if _is_active():
		visible = true
		set_process(true)
		monitoring = true
		monitorable = true
		
		# รีเซ็ต QTE progress ถ้ายังไม่เคยทำ
		if not QTEManager.is_fully_completed(quest_id):
			QTEManager.reset_progress(quest_id)
	else:
		visible = false
		set_process(false)
		monitoring = false
		monitorable = false

func _on_day_changed(_new_day: int):
	"""เมื่อเปลี่ยนวัน"""
	_check_if_active_today()
	_update_progress_display()
