# drawing_minigame.gd
extends CanvasLayer

signal completed  # สัญญาณเมื่อเล่นจบ

@onready var panel = $Panel
@onready var background_texture = $Panel/BackgroundTexture
@onready var drawing_canvas = $Panel/DrawingCanvas  # Node2D สำหรับวาด
@onready var drawing_area = $Panel/DrawingArea
@onready var title_label = $GamePanel/MarginContainer/VBoxContainer/TitleLabel
@onready var instruction_label = $GamePanel/MarginContainer/VBoxContainer/InstructionLabel
@onready var progress_label = $GamePanel/MarginContainer/VBoxContainer/StrokeCountLabel

# การตั้งค่า
var min_strokes_needed: int = 2  # จำนวนเส้นขั้นต่ำที่ต้องการ
var min_points_per_stroke: int = 5  # จุดขั้นต่ำในแต่ละเส้น
var stroke_distance_threshold: float = 100.0  # ระยะห่างสูงสุดระหว่างจุดในเส้นเดียวกัน
var min_distance_between_points: float = 2.0  # ระยะขั้นต่ำระหว่างจุด (เพิ่มความสมูท)
var closed_loop_threshold: float = 30.0  # ระยะที่ถือว่าวงปิด (จุดแรกกับจุดสุดท้ายใกล้กัน)

# ข้อมูลการวาด
var current_stroke: Array = []  # จุดในเส้นปัจจุบัน
var all_strokes: Array = []  # เก็บทุกเส้นที่วาด
var is_drawing: bool = false
var is_active: bool = false

# สี
var draw_color: Color = Color.BLACK
var line_width: float = 4.0

func _ready():
	hide()
	
	# ตั้งค่า Drawing Area
	if drawing_area:
		drawing_area.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# เชื่อม _draw() กับ DrawingCanvas
	if drawing_canvas:
		drawing_canvas.draw.connect(_on_canvas_draw)
	
	# ทดสอบถ้ารันเป็น scene หลัก
	if get_parent() == get_tree().root:
		start_minigame()

func start_minigame():
	"""เริ่มมินิเกม"""
	print("[DrawingMinigame] เริ่มมินิเกม")
	show()
	is_active = true
	all_strokes.clear()
	current_stroke.clear()
	_update_ui()
	
	# ล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		if player.has_method("set_can_move"):
			player.set_can_move(false)

func _input(event):
	if not is_active:
		return
	
	# ตรวจจับการวาด
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_start_stroke(event.position)
			else:
				_end_stroke()
	
	elif event is InputEventMouseMotion and is_drawing:
		_add_point_to_stroke(event.position)

func _start_stroke(global_pos: Vector2):
	"""เริ่มวาดเส้นใหม่"""
	# ตรวจสอบว่าอยู่ในพื้นที่วาดหรือไม่
	if not _is_in_drawing_area(global_pos):
		return
	
	is_drawing = true
	current_stroke.clear()
	
	# แปลงตำแหน่ง Global → Local ของ DrawingCanvas
	var local_pos = _global_to_canvas_local(global_pos)
	current_stroke.append(local_pos)
	print("[DrawingMinigame] เริ่มวาดเส้นใหม่ที่ตำแหน่ง %s" % local_pos)

func _add_point_to_stroke(global_pos: Vector2):
	"""เพิ่มจุดในเส้นปัจจุบัน"""
	if not _is_in_drawing_area(global_pos):
		return
	
	var local_pos = _global_to_canvas_local(global_pos)
	
	# ตรวจสอบระยะห่างจากจุดล่าสุด
	if current_stroke.size() > 0:
		var last_point = current_stroke[-1]
		var distance = local_pos.distance_to(last_point)
		
		# ถ้าห่างเกินไป = ขาด = เส้นใหม่
		if distance > stroke_distance_threshold:
			_end_stroke()
			_start_stroke(global_pos)
			return
		
		# เพิ่มจุดก็ต่อเมื่อห่างพอสมควร (ทำให้สมูท)
		if distance < min_distance_between_points:
			return
	
	current_stroke.append(local_pos)
	if drawing_canvas:
		drawing_canvas.queue_redraw()

func _end_stroke():
	"""จบการวาดเส้น"""
	if not is_drawing:
		return
	
	is_drawing = false
	
	# ตรวจสอบว่าเส้นมีจุดเพียงพอหรือไม่
	if current_stroke.size() < min_points_per_stroke:
		print("[DrawingMinigame] เส้นสั้นเกินไป (%d จุด)" % current_stroke.size())
		current_stroke.clear()
		if drawing_canvas:
			drawing_canvas.queue_redraw()
		return
	
	# ตรวจสอบว่าวงปิดหรือไม่ (จุดแรกกับจุดสุดท้ายต้องใกล้กัน)
	var first_point = current_stroke[0]
	var last_point = current_stroke[-1]
	var distance = first_point.distance_to(last_point)
	
	if distance <= closed_loop_threshold:
		# วงปิด! บันทึกเส้น
		all_strokes.append(current_stroke.duplicate())
		print("[DrawingMinigame] ✓ วงปิดสมบูรณ์! บันทึกเส้นที่ %d (มี %d จุด, ระยะปิด: %.1f)" % [all_strokes.size(), current_stroke.size(), distance])
	else:
		# ไม่ปิดวง
		print("[DrawingMinigame] ✗ วงไม่ปิด (ระยะห่าง: %.1f, ต้องไม่เกิน %.1f)" % [distance, closed_loop_threshold])
	
	current_stroke.clear()
	_update_ui()
	_check_completion()
	if drawing_canvas:
		drawing_canvas.queue_redraw()

func _is_in_drawing_area(global_pos: Vector2) -> bool:
	"""ตรวจสอบว่าตำแหน่งอยู่ในพื้นที่วาดหรือไม่"""
	if not drawing_area:
		return false
	
	var area_rect = drawing_area.get_global_rect()
	return area_rect.has_point(global_pos)

func _global_to_canvas_local(global_pos: Vector2) -> Vector2:
	"""แปลงตำแหน่ง Global เป็น Local ของ DrawingCanvas"""
	if not drawing_canvas:
		return global_pos
	
	# แปลง: Global → DrawingCanvas Local
	return drawing_canvas.to_local(global_pos)

func _on_canvas_draw():
	"""วาดเส้นทั้งหมดบน DrawingCanvas"""
	if not drawing_canvas:
		return
	
	# วาดเส้นที่บันทึกแล้ว (สีเต็ม)
	for stroke in all_strokes:
		_draw_stroke(stroke, draw_color)
	
	# วาดเส้นปัจจุบัน (สีสว่างกว่า)
	if current_stroke.size() > 0:
		_draw_stroke(current_stroke, draw_color.lightened(0.3))

func _draw_stroke(stroke: Array, color: Color):
	"""วาดเส้นหนึ่งเส้นด้วย Antialiasing"""
	if stroke.size() < 2:
		return
	
	# วาดทีละจุดเพื่อความสมูท
	for i in range(stroke.size() - 1):
		var point1 = stroke[i]
		var point2 = stroke[i + 1]
		drawing_canvas.draw_line(point1, point2, color, line_width, true)  # true = antialiased

func _update_ui():
	"""อัปเดต UI"""
	var strokes_count = all_strokes.size()
	
	progress_label.text = "เส้นที่วาด: %d/%d" % [strokes_count, min_strokes_needed]
	
	if strokes_count >= min_strokes_needed:
		instruction_label.text = "เสร็จสิ้น!"
		instruction_label.modulate = Color.GREEN
		progress_label.text = "✓ ผ่าน"
		progress_label.modulate = Color.GREEN
	else:
		instruction_label.text = "วาด %d รูป" % min_strokes_needed
		instruction_label.modulate = Color.WHITE
		progress_label.text = "วาดอะไรก็ได้ที่คิดว่าก้อนเมฆนี้เป็น!"
		progress_label.modulate = Color.WHITE

func _check_completion():
	"""ตรวจสอบว่าผ่านเงื่อนไขหรือยัง"""
	if all_strokes.size() >= min_strokes_needed:
		_complete_minigame()

func _complete_minigame():
	"""จบมินิเกม"""
	if not is_active:
		return
	
	print("[DrawingMinigame] มินิเกมเสร็จสิ้น!")
	is_active = false
	
	# อัปเดต UI
	_update_ui()
	
	# รอ 1.5 วินาที
	await get_tree().create_timer(1.5).timeout
	
	# ปลดล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	
	# ส่งสัญญาณว่าเสร็จแล้ว
	completed.emit()
	print("[DrawingMinigame] ส่งสัญญาณ 'completed'")

# ฟังก์ชันเสริม: เคลียร์การวาด
func clear_drawing():
	"""ล้างการวาดทั้งหมด"""
	all_strokes.clear()
	current_stroke.clear()
	if drawing_canvas:
		drawing_canvas.queue_redraw()
	_update_ui()

# ฟังก์ชันเสริม: ตั้งค่ารูปพื้นหลัง
func set_background_image(texture: Texture2D):
	"""ตั้งรูปพื้นหลัง"""
	if background_texture:
		background_texture.texture = texture
