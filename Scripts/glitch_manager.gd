# AutoLoad: GlitchManager
# จัดการ Glitch Effect สำหรับวันที่ 6
extends Node

var glitch_shader: Shader
var glitch_material: ShaderMaterial

# เก็บ nodes ที่ใส่ shader
var affected_nodes: Array = []

# ระดับ glitch (0.0 - 1.0)
@export var glitch_intensity: float = 0.0

# Pixelation settings
@export var pixel_size: float = 4.0
@export var color_corruption: float = 0.3

func _ready():
	# โหลด shader
	glitch_shader = load("res://Resources/Shaders/glitch_effect.gdshader")
	
	if not glitch_shader:
		push_error("[GlitchManager] ไม่พบ shader ที่ res://Resources/Shaders/glitch_effect.gdshader")
		return
	
	# สร้าง material
	glitch_material = ShaderMaterial.new()
	glitch_material.shader = glitch_shader
	
	# ตั้งค่าเริ่มต้น
	_update_shader_params()
	
	# เชื่อมต่อกับ DayManager
	if DayManager:
		DayManager.day_changed.connect(_on_day_changed)
		
		# เช็คว่าเป็นวันที่ 6 หรือไม่ตอนเริ่มเกม
		await get_tree().process_frame
		if DayManager.get_current_day() == 6:
			activate_glitch()

func _on_day_changed(new_day: int, _date_text: String):
	if new_day == 6:
		print("[GlitchManager] เข้าสู่วันที่ 6 - เปิด Glitch Effect")
		activate_glitch()
	else:
		print("[GlitchManager] ปิด Glitch Effect")
		deactivate_glitch()

func activate_glitch():
	"""เปิด glitch effect (ใช้เฉพาะ nodes ที่อยู่ใน group 'glitchable')"""
	print("[GlitchManager] กำลังเปิด Glitch Effect...")
	
	# ค้นหาเฉพาะ nodes ที่อยู่ใน group "glitchable"
	_apply_shader_to_glitchable_nodes()
	
	if affected_nodes.is_empty():
		print("[GlitchManager] ⚠ ไม่พบ nodes ใน group 'glitchable'")
		print("[GlitchManager] โปรดเพิ่ม Sprite2D/AnimatedSprite2D/TileMapLayer เข้า group 'glitchable'")
		return
	
	# Fade in glitch effect
	var tween = create_tween()
	tween.tween_property(self, "glitch_intensity", 0.5, 2.0)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_update_shader_params)

func deactivate_glitch():
	"""ปิด glitch effect"""
	print("[GlitchManager] กำลังปิด Glitch Effect...")
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "glitch_intensity", 0.0, 1.5)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		_remove_shader_from_all()
		_update_shader_params()
	)

func _apply_shader_to_glitchable_nodes():
	"""ใส่ shader ให้กับ nodes ที่อยู่ใน group 'glitchable' เท่านั้น"""
	affected_nodes.clear()
	
	# ดึง nodes จาก group "glitchable"
	var glitchable_nodes = get_tree().get_nodes_in_group("glitchable")
	
	if glitchable_nodes.is_empty():
		return
	
	print("[GlitchManager] พบ nodes ใน group 'glitchable': %d nodes" % glitchable_nodes.size())
	
	for node in glitchable_nodes:
		if _is_valid_glitch_node(node):
			_apply_shader_to_node(node)
			affected_nodes.append(node)
			print("[GlitchManager]   ✓ ใส่ shader ให้: %s" % node.name)
		else:
			print("[GlitchManager]   ✗ ข้าม: %s (ไม่ใช่ Sprite2D/AnimatedSprite2D/TileMapLayer)" % node.name)
	
	print("[GlitchManager] ใส่ shader สำเร็จ: %d nodes" % affected_nodes.size())

func _is_valid_glitch_node(node) -> bool:
	"""เช็คว่าเป็น node ที่รองรับหรือไม่"""
	return node is Sprite2D or node is AnimatedSprite2D or node.is_class("TileMapLayer")

func _apply_shader_to_node(node):
	"""ใส่ shader ให้กับ node"""
	if not node:
		return
	
	# สร้าง material ใหม่สำหรับแต่ละ node
	var mat = ShaderMaterial.new()
	mat.shader = glitch_shader
	
	# คัดลอกค่าพารามิเตอร์
	mat.set_shader_parameter("glitch_strength", glitch_intensity)
	mat.set_shader_parameter("color_shift_amount", glitch_intensity * 0.5)
	mat.set_shader_parameter("scan_line_speed", 1.0)
	mat.set_shader_parameter("distortion_speed", 0.5)
	mat.set_shader_parameter("pixel_size", pixel_size)
	mat.set_shader_parameter("color_corruption", color_corruption)
	
	node.material = mat

func _remove_shader_from_all():
	"""ลบ shader จากทุก node"""
	for node in affected_nodes:
		if is_instance_valid(node):
			node.material = null
	
	affected_nodes.clear()

func _update_shader_params():
	"""อัปเดตพารามิเตอร์ shader"""
	for node in affected_nodes:
		if is_instance_valid(node) and node.material is ShaderMaterial:
			node.material.set_shader_parameter("glitch_strength", glitch_intensity)
			node.material.set_shader_parameter("color_shift_amount", glitch_intensity * 0.5)
			node.material.set_shader_parameter("pixel_size", pixel_size)
			node.material.set_shader_parameter("color_corruption", color_corruption)

func set_glitch_intensity(value: float):
	"""ปรับความเข้มของ glitch (0.0 - 1.0)"""
	glitch_intensity = clamp(value, 0.0, 1.0)
	_update_shader_params()

func set_pixel_size(value: float):
	"""ปรับขนาด pixel (1.0 - 32.0)"""
	pixel_size = clamp(value, 1.0, 32.0)
	_update_shader_params()

func set_color_corruption(value: float):
	"""ปรับความเพี้ยนของสี (0.0 - 1.0)"""
	color_corruption = clamp(value, 0.0, 1.0)
	_update_shader_params()

func pulse_glitch(duration: float = 0.5, max_intensity: float = 0.8):
	"""สร้าง glitch pulse แบบชั่วคราว"""
	var original = glitch_intensity
	
	var tween = create_tween()
	tween.tween_property(self, "glitch_intensity", max_intensity, duration * 0.3)
	tween.tween_property(self, "glitch_intensity", original, duration * 0.7)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.step_finished.connect(func(_idx):
		_update_shader_params()
	)

func add_node_to_glitch(node: Node):
	"""เพิ่ม node เข้า glitch effect ทันที (ไม่ต้องใช้ group)"""
	if not _is_valid_glitch_node(node):
		push_error("[GlitchManager] Node ต้องเป็น Sprite2D, AnimatedSprite2D หรือ TileMapLayer")
		return
	
	if node in affected_nodes:
		print("[GlitchManager] Node นี้มี shader อยู่แล้ว")
		return
	
	_apply_shader_to_node(node)
	affected_nodes.append(node)
	print("[GlitchManager] เพิ่ม %s เข้า glitch effect" % node.name)

func remove_node_from_glitch(node: Node):
	"""ลบ node ออกจาก glitch effect"""
	if node not in affected_nodes:
		return
	
	if is_instance_valid(node):
		node.material = null
	
	affected_nodes.erase(node)
	print("[GlitchManager] ลบ %s ออกจาก glitch effect" % node.name)
