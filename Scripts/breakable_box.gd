# breakable_box.gd
extends RigidBody2D

signal box_destroyed  # สัญญาณเมื่อกล่องถูกทำลาย

@onready var sprite = $Sprite2D
@onready var progress_bar = $ProgressBar
@onready var collision_shape = $CollisionShape2D

var break_time: float = 2.0  # เวลาที่ต้องกดค้าง (วินาที)
var current_progress: float = 0.0
var is_pressing: bool = false
var is_destroyed: bool = false
var mouse_over: bool = false

# สีของกล่อง
var box_color: Color = Color("8B4513")  # น้ำตาล

func _ready():
	# ตั้งค่าเริ่มต้น
	progress_bar.value = 0
	
	# ตั้งสีให้ Sprite
	sprite.modulate = box_color
	
	# เปิดการตรวจจับ input
	input_pickable = true
	
	# Connect mouse signals
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _process(delta):
	if is_destroyed:
		return
	
	if is_pressing:
		# เพิ่ม progress
		current_progress += delta
		var percent = (current_progress / break_time) * 100.0
		
		# อัปเดต UI
		progress_bar.value = percent
		
		# เปลี่ยนสีตาม progress (จางลง)
		var color_value = 1.0 - (current_progress / break_time)
		sprite.modulate = box_color * color_value
		
		# เช็ควาทำลายหรือยัง
		if current_progress >= break_time:
			_destroy_box()
	else:
		# ถ้าปล่อยปุ่ม ให้ progress ลดลง
		if current_progress > 0:
			current_progress -= delta * 0.5  # ลดช้ากว่าเพิ่ม
			current_progress = max(0, current_progress)
			
			var percent = (current_progress / break_time) * 100.0
			progress_bar.value = percent
			
			# คืนสี
			var color_value = 1.0 - (current_progress / break_time)
			sprite.modulate = box_color.lerp(box_color, 1.0 - color_value)

func _input(event):
	if is_destroyed:
		return
	
	# ตรวจจับการกดเมาส์บนกล่อง
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if mouse_over:  # ต้องอยู่บนกล่อง
				if event.pressed:
					is_pressing = true
					print("[Box] เริ่มกดค้าง")
				else:
					is_pressing = false
					print("[Box] ปล่อยปุ่ม (progress: %.1f%%)" % ((current_progress / break_time) * 100))
			else:
				# ถ้าปล่อยนอกกล่อง ให้หยุดกด
				if not event.pressed:
					is_pressing = false

func _on_mouse_entered():
	"""เมื่อเมาส์เข้ากล่อง"""
	mouse_over = true
	# เปลี่ยนสีเล็กน้อยเพื่อแสดงว่า hover
	if not is_destroyed:
		sprite.modulate = box_color * 1.2

func _on_mouse_exited():
	"""เมื่อเมาส์ออกจากกล่อง"""
	mouse_over = false
	# คืนสี
	if not is_destroyed and not is_pressing:
		var color_value = 1.0 - (current_progress / break_time)
		sprite.modulate = box_color * color_value

func _destroy_box():
	"""ทำลายกล่อง"""
	if is_destroyed:
		return
	
	is_destroyed = true
	is_pressing = false
	print("[Box] กล่องถูกทำลาย!")
	
	# ปิด collision
	collision_shape.set_deferred("disabled", true)
	
	# เพิ่มแรงระเบิดเล็กน้อย
	var explosion_force = Vector2(randf_range(-200, 200), -300)
	apply_central_impulse(explosion_force)
	
	# แอนิเมชันหาย
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_property(progress_bar, "modulate:a", 0.0, 0.5)
	tween.tween_property(sprite, "scale", Vector2(0.3, 0.3), 0.5)
	
	await tween.finished
	
	# ส่งสัญญาณ
	box_destroyed.emit()
	
	# ซ่อนกล่อง
	hide()

func reset_box():
	"""รีเซ็ตกล่องสำหรับเล่นใหม่"""
	show()
	is_destroyed = false
	is_pressing = false
	current_progress = 0.0
	mouse_over = false
	
	# รีเซ็ต physics
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	
	# รีเซ็ต UI
	sprite.modulate = box_color
	sprite.scale = Vector2.ONE
	progress_bar.modulate.a = 1.0
	progress_bar.value = 0
	
	# เปิด collision
	collision_shape.disabled = false
