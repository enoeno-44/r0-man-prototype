extends CanvasLayer

signal qte_completed(success: bool)

@onready var timing_bar = $Panel/TimingBar
@onready var hit_zone = $Panel/HitZone
@onready var indicator = $Panel/Indicator
@onready var instruction_label = $Panel/InstructionLabel
@onready var progress_label = $Panel/ProgressLabel

# ตัวแปรควบคุม QTE
var qte_speed: float = 150.0
var indicator_position: float = 0.0
var is_playing: bool = false
var has_pressed: bool = false
var direction: int = 1

# ตัวแปร HitZone
var hit_zone_start: float = 10.0
var hit_zone_end: float = 60.0

# การตั้งค่า
@export var min_speed: float = 100.0
@export var max_speed: float = 250.0
@export var min_hit_zone_size: float = 15.0
@export var max_hit_zone_size: float = 25.0


func _ready():
	timing_bar.max_value = 100
	timing_bar.value = 0
	instruction_label.text = "Press SPACE!"
	hide()

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
	update_indicator_position()
	
	if Input.is_action_just_pressed("ui_accept") and not has_pressed:
		has_pressed = true
		check_success()


func start_qte():
	"""เริ่ม QTE รอบใหม่"""
	show()
	indicator_position = 0.0
	is_playing = true
	has_pressed = false
	direction = 1
	timing_bar.value = 0
	instruction_label.text = "Press SPACE!"
	instruction_label.modulate = Color.WHITE
	
	randomize_speed()
	randomize_hit_zone()

func randomize_speed():
	"""สุ่มความเร็วของ Indicator"""
	qte_speed = randf_range(min_speed, max_speed)
	print("QTE Speed: %.1f" % qte_speed)

func randomize_hit_zone():
	"""สุ่มตำแหน่งและขนาดของ HitZone"""
	var zone_size = randf_range(min_hit_zone_size, max_hit_zone_size)
	var min_start = 10.0
	var max_start = 90.0 - zone_size
	
	hit_zone_start = randf_range(min_start, max_start)
	hit_zone_end = hit_zone_start + zone_size
	
	await get_tree().process_frame
	update_hit_zone_ui(zone_size)
	print("HitZone: %.1f%% - %.1f%% (size: %.1f%%)" % [hit_zone_start, hit_zone_end, zone_size])

func update_hit_zone_ui(zone_size: float):
	"""อัพเดทตำแหน่งและขนาด HitZone บน UI"""
	var bar_width = timing_bar.size.x
	if bar_width > 0:
		hit_zone.position.x = timing_bar.position.x + (bar_width * hit_zone_start / 100.0)
		hit_zone.size.x = bar_width * (zone_size / 100.0)

func update_indicator_position():
	"""อัพเดทตำแหน่ง Indicator"""
	var bar_width = timing_bar.size.x
	if bar_width > 0:
		indicator.position.x = timing_bar.position.x + (bar_width * indicator_position / 100.0)

func check_success():
	"""ตรวจสอบว่ากดถูกหรือผิด"""
	is_playing = false
	var success = (indicator_position >= hit_zone_start and indicator_position <= hit_zone_end)
	
	if success:
		instruction_label.text = "Success!"
		instruction_label.modulate = Color.GREEN
	else:
		instruction_label.text = "Failed!"
		instruction_label.modulate = Color.RED
	
	await get_tree().create_timer(0.5).timeout
	qte_completed.emit(success)

func set_progress_text(current: int, required: int):
	"""อัพเดทข้อความ Progress"""
	if progress_label:
		progress_label.text = "สำเร็จ: %d/%d" % [current, required]

func reset_speed():
	"""รีเซ็ตความเร็ว"""
	qte_speed = 150.0
