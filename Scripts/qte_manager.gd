extends Node

signal qte_success(object_id: String, current_count: int, required_count: int)
signal qte_failed(object_id: String, current_count: int, required_count: int)
signal qte_fully_completed(object_id: String)

var qte_progress: Dictionary = {}

var is_qte_active: bool = false
var current_object_id: String = ""
var qte_ui: CanvasLayer = null

func _ready():
	var qte_scene = load("res://Scenes/qte_ui.tscn")
	qte_ui = qte_scene.instantiate()
	add_child(qte_ui)
	qte_ui.hide()
	qte_ui.qte_completed.connect(_on_qte_completed)

func register_qte(object_id: String, required_count: int):
	if object_id not in qte_progress:
		qte_progress[object_id] = {
			"current": 0,
			"required": required_count
		}

func is_fully_completed(object_id: String) -> bool:
	if object_id not in qte_progress:
		return false
	var data = qte_progress[object_id]
	return data.current >= data.required

func get_progress(object_id: String) -> Dictionary:
	if object_id in qte_progress:
		return qte_progress[object_id]
	return { "current": 0, "required": 0 }

func start_qte(object_id: String):
	if not object_id in qte_progress:
		push_error("Object ID '%s' ยังไม่ได้ลงทะเบียน!" % object_id)
		return
	
	if is_fully_completed(object_id):
		print("QTE นี้ทำครบแล้ว!")
		qte_fully_completed.emit(object_id)
		return
	
	if is_qte_active:
		print("QTE กำลังเล่นอยู่")
		return
	
	is_qte_active = true
	current_object_id = object_id
	freeze_player(true)
	
	var progress = get_progress(object_id)
	qte_ui.set_progress_text(progress.current, progress.required)
	
	qte_ui.start_qte()

func _on_qte_completed(success: bool):
	var progress = get_progress(current_object_id)
	
	if success:
		qte_progress[current_object_id].current += 1
		progress = get_progress(current_object_id)
		qte_success.emit(current_object_id, progress.current, progress.required)
		
		if is_fully_completed(current_object_id):
			qte_ui.hide()
			is_qte_active = false
			freeze_player(false)
			qte_fully_completed.emit(current_object_id)
			current_object_id = ""
		else:
			is_qte_active = false  # รีเซ็ตก่อน
			await get_tree().create_timer(0.3).timeout
			start_qte(current_object_id)  # เริ่มใหม่
	else:
		qte_ui.hide()
		freeze_player(false)
		qte_failed.emit(current_object_id, progress.current, progress.required)
		is_qte_active = false
		current_object_id = ""

func reset_progress(object_id: String):
	if object_id in qte_progress:
		qte_progress[object_id].current = 0

func get_save_data() -> Dictionary:
	return { "qte_progress": qte_progress }

func load_save_data(data: Dictionary):
	if "qte_progress" in data:
		qte_progress = data.qte_progress

func freeze_player(freeze: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)
