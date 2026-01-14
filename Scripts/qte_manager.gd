extends Node

signal qte_success(object_id: String, current_count: int, required_count: int)
signal qte_failed(object_id: String, current_count: int, required_count: int)
signal qte_fully_completed(object_id: String)

var qte_progress: Dictionary = {}
var is_qte_active: bool = false
var current_object_id: String = ""

# UI Components
var qte_ui: CanvasLayer = null
var timing_bar: ProgressBar
var hit_zone: ColorRect
var indicator: ColorRect
var instruction_label: Label
var progress_label: Label

# QTE Variables
var qte_speed: float = 150.0
var indicator_position: float = 0.0
var is_playing: bool = false
var has_pressed: bool = false
var direction: int = 1
var hit_zone_start: float = 10.0
var hit_zone_end: float = 60.0

# Settings
@export var min_speed: float = 100.0
@export var max_speed: float = 250.0
@export var min_hit_zone_size: float = 15.0
@export var max_hit_zone_size: float = 25.0

func _ready():
	_create_ui()

func _process(delta):
	if not is_playing:
		return
	
	indicator_position += qte_speed * direction * delta
	
	if indicator_position >= 100:
		indicator_position = 100
		direction = -1
	elif indicator_position <= 0:
		indicator_position = 0
		direction = 1
	
	timing_bar.value = indicator_position
	_update_indicator_position()
	
	if Input.is_action_just_pressed("ui_accept") and not has_pressed:
		has_pressed = true
		_check_success()

# ==================== UI Creation ====================
func _create_ui():
	qte_ui = CanvasLayer.new()
	add_child(qte_ui)
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(400, 150)
	panel.position = Vector2(460, 275)
	qte_ui.add_child(panel)
	
	timing_bar = ProgressBar.new()
	timing_bar.position = Vector2(50, 50)
	timing_bar.size = Vector2(300, 20)
	timing_bar.max_value = 100
	timing_bar.value = 0
	timing_bar.show_percentage = false
	var style_empty = StyleBoxEmpty.new()
	timing_bar.add_theme_stylebox_override("fill", style_empty)
	panel.add_child(timing_bar)
	
	hit_zone = ColorRect.new()
	hit_zone.color = Color(100, 100, 70)
	hit_zone.size = Vector2(30, 20)
	hit_zone.position.y = 40
	panel.add_child(hit_zone)
	
	indicator = ColorRect.new()
	indicator.color = Color(1, 0, 0, 0.8)
	indicator.size = Vector2(5, 25)
	indicator.position.y = timing_bar.position.y - 2.5
	panel.add_child(indicator)
	
	instruction_label = Label.new()
	instruction_label.text = "Press SPACE!"
	instruction_label.custom_minimum_size.x = 400 
	instruction_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER 
	instruction_label.position.y = 15
	panel.add_child(instruction_label) 
	
	progress_label = Label.new()
	progress_label.custom_minimum_size.x = 400
	progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	progress_label.position.y = 95
	panel.add_child(progress_label)
	
	
	qte_ui.hide()

# ==================== QTE Management ====================
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

func is_active() -> bool:
	return is_qte_active

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
	_set_progress_text(progress.current, progress.required)
	_start_qte_round()

func _start_qte_round():
	qte_ui.show()
	indicator_position = 0.0
	is_playing = true
	has_pressed = false
	direction = 1
	timing_bar.value = 0
	instruction_label.text = "Press SPACE!"
	instruction_label.modulate = Color.WHITE
	
	_randomize_speed()
	_randomize_hit_zone()

func _randomize_speed():
	qte_speed = randf_range(min_speed, max_speed)

func _randomize_hit_zone():
	var zone_size = randf_range(min_hit_zone_size, max_hit_zone_size)
	var min_start = 10.0
	var max_start = 90.0 - zone_size
	
	hit_zone_start = randf_range(min_start, max_start)
	hit_zone_end = hit_zone_start + zone_size
	
	await get_tree().process_frame
	_update_hit_zone_ui(zone_size)

func _update_hit_zone_ui(zone_size: float):
	var bar_width = timing_bar.size.x
	if bar_width > 0:
		hit_zone.position.x = timing_bar.position.x + (bar_width * hit_zone_start / 100.0)
		hit_zone.size.x = bar_width * (zone_size / 100.0)

func _update_indicator_position():
	var bar_width = timing_bar.size.x
	if bar_width > 0:
		indicator.position.x = timing_bar.position.x + (bar_width * indicator_position / 100.0)

func _check_success():
	is_playing = false
	var success = (indicator_position >= hit_zone_start and indicator_position <= hit_zone_end)
	
	if success:
		instruction_label.text = "Success!"
		instruction_label.modulate = Color.GREEN
	else:
		instruction_label.text = "Failed!"
		instruction_label.modulate = Color.RED
	
	await get_tree().create_timer(0.5).timeout
	_on_qte_completed(success)

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
			is_qte_active = false
			await get_tree().create_timer(0.3).timeout
			start_qte(current_object_id)
	else:
		qte_ui.hide()
		freeze_player(false)
		qte_failed.emit(current_object_id, progress.current, progress.required)
		is_qte_active = false
		current_object_id = ""

func _set_progress_text(current: int, required: int):
	if progress_label:
		progress_label.text = "สำเร็จ: %d/%d" % [current, required]

func reset_progress(object_id: String):
	if object_id in qte_progress:
		qte_progress[object_id].current = 0
		print("[QTEManager] Reset progress สำหรับ %s" % object_id)

func reset_all_progress():
	"""รีเซ็ต QTE progress ทั้งหมด"""
	for obj_id in qte_progress.keys():
		qte_progress[obj_id].current = 0
	print("[QTEManager] Reset progress ทั้งหมด")

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
