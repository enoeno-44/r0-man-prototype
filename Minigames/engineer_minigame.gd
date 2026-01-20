# engineer_minigame.gd
extends CanvasLayer

signal completed  # สัญญาณเมื่อสำเร็จ
signal failed     # สัญญาณเมื่อล้มเหลว

# ===== Node References =====
@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var instruction_label = $Panel/VBoxContainer/InstructionLabel
@onready var force_label = $Panel/VBoxContainer/StatsContainer/ForceLabel
@onready var damage_label = $Panel/VBoxContainer/StatsContainer/DamageLabel
@onready var chip_slot = $Panel/GameArea/ChipSlot
@onready var chip_sprite = $Panel/GameArea/ChipSprite
@onready var force_bar = $Panel/GameArea/ForceBar

# ===== Game Variables =====
var is_active: bool = false
var is_pressing: bool = false

# ค่าหลัก
var current_force: float = 0.0        # แรงดึงปัจจุบัน (0-100)
var current_damage: float = 0.0       # ความเสียหาย (0-100)
var extraction_progress: float = 0.0  # ความคืบหน้าการดึง (0-100)

# พารามิเตอร์ที่ปรับได้
var force_increase_speed: float = 40.0   # ความเร็วเพิ่มแรงต่อวินาที
var force_decrease_speed: float = 60.0   # ความเร็วลดแรงเมื่อไม่กด
var safe_force_min: float = 30.0         # แรงขั้นต่ำที่เริ่มดึงได้
var safe_force_max: float = 70.0         # แรงสูงสุดที่ปลอดภัย
var damage_increase_speed: float = 50.0  # ความเร็วเพิ่ม Damage เมื่อแรงมากเกิน
var extraction_speed: float = 15.0       # ความเร็วดึงชิปออกมา
var max_damage: float = 100.0            # Damage สูงสุด
var extraction_goal: float = 100.0       # เป้าหมายการดึง
# ตัวแปรสำหรับ Feedback
var shake_intensity: float = 0.0
var original_chip_position: Vector2

func _ready():
	hide()
	# บันทึกตำแหน่งเดิมของชิป
	if chip_sprite:
		original_chip_position = chip_sprite.position
	
	# ถ้าเปิด Scene นี้แบบ Standalone ให้เริ่มเกมทันที
	if get_parent() == get_tree().root:
		start_minigame()

func start_minigame():
	"""เริ่มมินิเกม"""
	print("[ChipExtraction] เริ่มมินิเกม")
	show()
	is_active = true
	is_pressing = false
	
	# รีเซ็ตค่า
	current_force = 0.0
	current_damage = 0.0
	extraction_progress = 0.0
	shake_intensity = 0.0
	
	_update_ui()
	_update_chip_position()

func _process(delta):
	if not is_active:
		return
	
	# เช็คการกดปุ่ม (Space หรือ Click ซ้าย)
	is_pressing = Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	# === อัปเดตแรงดึง ===
	if is_pressing:
		# กดค้าง → เพิ่มแรง
		current_force = min(100.0, current_force + force_increase_speed * delta)
	else:
		# ปล่อย → ลดแรง
		current_force = max(0.0, current_force - force_decrease_speed * delta)
	
	# === เช็คว่าแรงอยู่ในช่วงที่เหมาะสม ===
	if current_force >= safe_force_min and current_force <= safe_force_max:
		# ✅ ดึงได้! ชิปขยับออกมา
		extraction_progress += extraction_speed * delta
		shake_intensity = 0.0  # ไม่สั่น
		
	elif current_force > safe_force_max:
		# ❌ แรงมากเกินไป! ชิปเสียหาย
		current_damage += damage_increase_speed * delta
		shake_intensity = 5.0  # สั่นเยอะ
		
	else:
		# แรงน้อยเกินไป - ไม่มีอะไรเกิดขึ้น
		shake_intensity = 0.0
	
	# === อัปเดต UI และ Feedback ===
	_update_ui()
	_update_chip_position()
	_apply_screen_shake()
	
	# === เช็คเงื่อนไขชนะ/แพ้ ===
	if extraction_progress >= extraction_goal:
		_win_minigame()
	elif current_damage >= max_damage:
		_lose_minigame()

func _update_ui():
	"""อัปเดตข้อความและ Progress Bar"""
	force_label.text = "แรงดึง: %d%%" % int(current_force)
	damage_label.text = "ความเสียหาย: %d%%" % int(current_damage)
	force_bar.value = current_force
	
	# เปลี่ยนสีตามสถานะ
	if current_force > safe_force_max:
		force_label.modulate = Color.RED
		damage_label.modulate = Color.RED
	elif current_force >= safe_force_min:
		force_label.modulate = Color.GREEN
		damage_label.modulate = Color.WHITE
	else:
		force_label.modulate = Color.YELLOW
		damage_label.modulate = Color.WHITE

func _update_chip_position():
	"""อัปเดตตำแหน่งชิป - ค่อยๆ ขึ้นตามความคืบหน้า"""
	if not chip_sprite:
		return
	
	# คำนวณตำแหน่ง Y (ขึ้นเมื่อดึงได้)
	var extraction_offset = -(extraction_progress / extraction_goal) * 200.0  # ขึ้นสูงสุด 200 pixel
	chip_sprite.position.y = original_chip_position.y + extraction_offset

func _apply_screen_shake():
	"""สั่นหน้าจอเมื่อแรงมากเกิน"""
	if shake_intensity > 0:
		var shake_x = randf_range(-shake_intensity, shake_intensity)
		var shake_y = randf_range(-shake_intensity, shake_intensity)
		panel.position = Vector2(shake_x, shake_y)
		
		# กระพริบสีแดง
		chip_sprite.modulate = Color.RED
	else:
		panel.position = Vector2.ZERO
		chip_sprite.modulate = Color.WHITE

func _win_minigame():
	"""ชนะ - ดึงชิปออกมาสำเร็จ"""
	print("[ChipExtraction] ชนะ! ดึงชิปออกมาสำเร็จ")
	is_active = false
	
	instruction_label.text = "สำเร็จ! ดึงชิปออกมาได้แล้ว"
	instruction_label.modulate = Color.GREEN
	
	# แสดงข้อความ 2 วินาที
	await get_tree().create_timer(2.0).timeout
	
	_unlock_player()
	hide()
	completed.emit()
	print("[ChipExtraction] ส่งสัญญาณ 'completed'")

func _lose_minigame():
	"""แพ้ - ชิปพังเพราะแรงมากเกิน"""
	print("[ChipExtraction] แพ้! ชิพเสียหายเกินไป")
	is_active = false
	
	instruction_label.text = "ล้มเหลว! ชิปเสียหายเกินไป"
	instruction_label.modulate = Color.RED
	chip_sprite.modulate = Color.RED
	
	# แสดงข้อความ 2 วินาที
	await get_tree().create_timer(2.0).timeout
	
	_unlock_player()
	hide()
	failed.emit()
	print("[ChipExtraction] ส่งสัญญาณ 'failed'")

func _unlock_player():
	"""ปลดล็อคผู้เล่น"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
