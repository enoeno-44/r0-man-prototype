extends CanvasLayer

signal completed  # สัญญาณเมื่อเล่นจบ

@onready var panel = $Panel
@onready var instruction_label = $Panel/VBoxContainer/InstructionLabel
@onready var progress_label = $Panel/VBoxContainer/ProgressLabel
@onready var press_count_label = $Panel/VBoxContainer/PressCountLabel

var presses_needed: int = 3
var current_presses: int = 0
var is_active: bool = false

func _ready():
	hide()  # ซ่อนตอนเริ่มต้น
	if get_parent() == get_tree().root:
			start_minigame()
func start_minigame():
	"""เริ่มมินิเกม"""
	print("[SimpleMinigame] เริ่มมินิเกม")
	show()
	is_active = true
	current_presses = 0
	_update_ui()
	
	# ปิดการควบคุมผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		if player.has_method("set_can_move"):
			player.set_can_move(false)

func _process(_delta):
	if not is_active:
		return
	
	# เช็คว่ากด Space
	if Input.is_action_just_pressed("ui_accept"):  # Space
		_on_button_pressed()

func _on_button_pressed():
	"""เมื่อกดปุ่ม"""
	current_presses += 1
	print("[SimpleMinigame] กด %d/%d ครั้ง" % [current_presses, presses_needed])
	_update_ui()
	
	# เช็คว่าครบหรือยัง
	if current_presses >= presses_needed:
		_complete_minigame()

func _update_ui():
	"""อัปเดต UI"""
	press_count_label.text = "กดไปแล้ว: %d/%d ครั้ง" % [current_presses, presses_needed]
	
	if current_presses >= presses_needed:
		instruction_label.text = "เสร็จสิ้น!"
		instruction_label.modulate = Color.GREEN
	else:
		instruction_label.text = "กด SPACE เพื่อช่วยยาย!"
		instruction_label.modulate = Color.WHITE

func _complete_minigame():
	"""จบมินิเกม"""
	print("[SimpleMinigame] มินิเกมเสร็จสิ้น!")
	is_active = false
	
	# แสดงข้อความเสร็จ 1 วินาที
	await get_tree().create_timer(1.0).timeout
	
	# ปลดล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	
	# ส่งสัญญาณว่าเสร็จแล้ว
	completed.emit()
	print("[SimpleMinigame] ส่งสัญญาณ 'completed'")
