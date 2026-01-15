extends CanvasLayer

# UI Elements
@onready var fade_rect: ColorRect
@onready var transition_label: Label

# Transition Settings
@export var fade_duration: float = 0.8
@export var text_display_duration: float = 1.0
@export var text_fade_duration: float = 0.5

var is_transitioning: bool = false

func _ready():
	# ตั้ง z-index สูงสุดเพื่อให้อยู่ข้างบนสุดเสมอ
	layer = 100
	
	_create_ui()
	_setup_connections()
	
	# Fade in เมื่อเริ่มเกม (แทน opening_canvas.gd)
	await get_tree().process_frame
	opening_fade_in()

func _create_ui():
	"""สร้าง UI สำหรับ transition"""
	
	# ColorRect สำหรับ fade
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)
	
	# Label สำหรับแสดงวันที่
	transition_label = Label.new()
	transition_label.name = "TransitionLabel"
	transition_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	transition_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(transition_label)
	
	# ซ่อนตอนเริ่มต้น
	fade_rect.modulate.a = 0.0
	transition_label.modulate.a = 0.0
	
	# ขอให้ resize ตาม viewport
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _setup_connections():
	"""เชื่อมสัญญาณจาก DayManager"""
	# ใช้ call_deferred เพราะ DayManager อาจจะยังไม่พร้อม
	call_deferred("_connect_signals")

func _connect_signals():
	if DayManager:
		DayManager.day_transition_started.connect(_on_day_transition_started)
		print("[TransitionManager] เชื่อมสัญญาณสำเร็จ")
	else:
		push_error("[TransitionManager] ไม่พบ DayManager")

func _on_viewport_size_changed():
	"""ปรับขนาดตาม viewport"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	if fade_rect:
		fade_rect.size = viewport_size
		fade_rect.position = Vector2.ZERO
	
	if transition_label:
		transition_label.size = viewport_size
		transition_label.position = Vector2.ZERO
		
		# ปรับขนาดฟอนต์
		var font_size = int(viewport_size.y / 10)  # ประมาณ 10% ของความสูง
		transition_label.add_theme_font_size_override("font_size", font_size)

# ==================== Opening Fade In ====================
func opening_fade_in():
	"""Fade in เมื่อเริ่มเกม (แทน opening_canvas.gd)"""
	print("[TransitionManager] Opening fade in")
	
	fade_rect.modulate.a = 1.0
	
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

# ==================== Day Transition ====================
func _on_day_transition_started():
	"""เริ่ม transition เมื่อข้ามวัน"""
	if is_transitioning:
		push_warning("[TransitionManager] Transition กำลังทำงานอยู่")
		return
	
	is_transitioning = true
	print("[TransitionManager] เริ่ม day transition")
	
	await _fade_out()
	await _show_date_text()
	await _fade_in()
	
	is_transitioning = false
	print("[TransitionManager] Day transition เสร็จสิ้น")

func _fade_out():
	"""จางหน้าจอเป็นสีดำ"""
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

func _show_date_text():
	"""แสดงข้อความวันที่"""
	if not DayManager:
		return
	
	transition_label.text = DayManager.get_current_date_text()
	
	# Fade in text
	var tween = create_tween()
	tween.tween_property(transition_label, "modulate:a", 1.0, text_fade_duration)
	await tween.finished
	
	# แสดงอยู่สักพัก
	await get_tree().create_timer(text_display_duration).timeout
	
	# Fade out text
	tween = create_tween()
	tween.tween_property(transition_label, "modulate:a", 0.0, text_fade_duration)
	await tween.finished

func _fade_in():
	"""จางหน้าจอกลับ"""
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

# ==================== Custom Transitions ====================
func custom_fade_out(duration: float = 1.0):
	"""Fade out แบบกำหนดเอง (ใช้สำหรับ scene transition อื่นๆ)"""
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

func custom_fade_in(duration: float = 1.0):
	"""Fade in แบบกำหนดเอง"""
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func show_text(text: String, duration: float = 2.0):
	"""แสดงข้อความกลางจอ"""
	transition_label.text = text
	
	var tween = create_tween()
	tween.tween_property(transition_label, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	await get_tree().create_timer(duration).timeout
	
	tween = create_tween()
	tween.tween_property(transition_label, "modulate:a", 0.0, 0.5)
	await tween.finished

# ==================== Scene Transition Helper ====================
func transition_to_scene(scene_path: String, fade_out_duration: float = 0.8, fade_in_duration: float = 0.8):
	"""เปลี่ยน scene พร้อม transition"""
	await custom_fade_out(fade_out_duration)
	get_tree().change_scene_to_file(scene_path)
	await custom_fade_in(fade_in_duration)

# ==================== Cleanup ====================
func _exit_tree():
	"""ทำความสะอาดเมื่อถูกลบ"""
	if DayManager and DayManager.day_transition_started.is_connected(_on_day_transition_started):
		DayManager.day_transition_started.disconnect(_on_day_transition_started)
