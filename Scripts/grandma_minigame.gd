extends CanvasLayer

signal completed  # สัญญาณเมื่อเล่นจบ

@onready var panel = $Panel
@onready var title_label = $Panel/VBoxContainer/TitleLabel
@onready var instruction_label = $Panel/VBoxContainer/InstructionLabel
@onready var progress_label = $Panel/VBoxContainer/ProgressLabel
@onready var article_container = $Panel/VBoxContainer/ScrollContainer/ArticleContainer
@onready var correction_panel = $Panel/CorrectionPanel
@onready var question_label = $Panel/CorrectionPanel/VBoxContainer/QuestionLabel
@onready var answer_edit = $Panel/CorrectionPanel/VBoxContainer/AnswerEdit
@onready var button_container = $Panel/CorrectionPanel/VBoxContainer/ButtonContainer
@onready var submit_button = $Panel/CorrectionPanel/VBoxContainer/ButtonContainer/SubmitButton
@onready var cancel_button = $Panel/CorrectionPanel/VBoxContainer/ButtonContainer/CancelButton

# ข้อมูลบทความจดหมายจากคุณยาย
var article_data = {
	"words": [
		"ลูกรัก ",
		"ตั้งแต่ลูกไปทำงาน ",
		"บ้านก็ดูเงียบลง",
		"มาก",
		"แม่อยากบอกว่าดอกไม้ที่ลูกปลูกไว้หน้า",
		"ข้าม",
		"แม่ยังคอยดูแลมันอยู่เหมือน",
		"เดิม",
		"\n\n",
		"ทุกครั้งที่มันออกดอก ",
		"แม่ก็อยากให้ลูกได้กลับมาดูด้วยตาตัวเอง ",
		"ว่าสิ่งที่ลูกตั้งใจปลูกไว้นั้นสวยแค่",
		"ไหน",
		"แม่รู้ว่าลูกเหนื่อยกับงาน ",
		"แต่แม่ไม่ได้โกรธที่ติดต่อกันได้น้อยลง ",
		"บางวันโทรไปไม่มี",
		"คน",
		"รับ",
		"ก็อดเป็นห่วงไม่ได้\n\n",
		"ได้แต่คิดว่าลูกสบายดีหรือเปล่า ",
		"ถ้า",
		"วันไหนลูกเหนื่อยหรือ",
		"ท้อ",
		" ",
		"อยาก",
		"ให้รู้ว่ายังมีบ้านหลังนี้ ",
		"มีพ่อกับแม่ที่รอฟังอยู่เสมอ\n\n",
		"เมื่อมีเวลา กลับมาดูดอกไม้ที่ลูก",
		"ปลูก",
		"ไว้บ้างนะ"
	],
	"errors": {
		3: {"wrong": "มาด", "correct": "มาก"},
		5: {"wrong": "ข้าน", "correct": "บ้าน"},
		7: {"wrong": "เดิน", "correct": "เดิม"},
		12: {"wrong": "ไหบ", "correct": "ไหน"},
		16: {"wrong": "ดน", "correct": "คน"},
		17: {"wrong": "รัน", "correct": "รับ"},
		20: {"wrong": "ก้า", "correct": "ถ้า"},
		22: {"wrong": "ก้อ", "correct": "ท้อ"},
		24: {"wrong": "อยาด", "correct": "อยาก"},
		28: {"wrong": "ปลูด", "correct": "ปลูก"},
	}
}

var word_labels = []
var errors_found: int = 0
var total_errors: int = 0
var current_error_index: int = -1
var is_active: bool = false

func _ready():
	hide()  # ซ่อนตอนเริ่มต้น
	total_errors = article_data.errors.size()
	
	# ถ้ารันเป็น scene หลัก ให้เริ่มเลย
	if get_parent() == get_tree().root:
		start_minigame()
	
	# เชื่อมต่อปุ่ม
	submit_button.pressed.connect(_on_submit_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)

func start_minigame():
	"""เริ่มมินิเกม"""
	print("[WordCorrection] เริ่มมินิเกมแก้ไขคำผิด")
	show()
	is_active = true
	errors_found = 0
	current_error_index = -1
	
	_setup_ui()
	_create_article()
	_update_progress()
	
	correction_panel.visible = false

func _setup_ui():
	"""ตั้งค่า UI"""
	title_label.text = "จดหมายจากคุณแม่"
	instruction_label.text = "คลิกที่คำที่คิดว่าผิด แล้วพิมพ์คำที่ถูกต้อง"

func _create_article():
	"""สร้างบทความ"""
	# ล้าง container
	for child in article_container.get_children():
		child.queue_free()
	
	word_labels.clear()
	
	# สร้าง VBoxContainer แทน HBoxContainer
	var current_paragraph = VBoxContainer.new()
	article_container.add_child(current_paragraph)
	
	var current_line = HBoxContainer.new()
	current_line.add_theme_constant_override("separation", 0)
	current_paragraph.add_child(current_line)
	
	var line_width = 0
	var max_width = 800  # ความกว้างสูงสุดของบรรทัด (ปรับตามขนาดจอ)
	
	for i in range(article_data.words.size()):
		var word = article_data.words[i]
		
		# ถ้าเจอ \n\n ให้สร้างย่อหน้าใหม่
		if word.contains("\n"):
			var parts = word.split("\n")
			for j in range(parts.size()):
				if parts[j] != "":
					var label = _create_word_label(parts[j], i)
					current_line.add_child(label)
					word_labels.append(label)
				
				# สร้างย่อหน้าใหม่หลังจาก \n\n
				if j < parts.size() - 1:
					current_paragraph = VBoxContainer.new()
					article_container.add_child(current_paragraph)
					current_line = HBoxContainer.new()
					current_line.add_theme_constant_override("separation", 0)
					current_paragraph.add_child(current_line)
					line_width = 0
		else:
			var label = _create_word_label(word, i)
			var word_width = word.length() * 15  # ประมาณขนาด
			
			# ถ้าเกินความกว้าง ให้ขึ้นบรรทัดใหม่
			if line_width + word_width > max_width:
				current_line = HBoxContainer.new()
				current_line.add_theme_constant_override("separation", 0)
				current_paragraph.add_child(current_line)
				line_width = 0
			
			current_line.add_child(label)
			word_labels.append(label)
			line_width += word_width

func _create_word_label(text: String, index: int) -> Label:
	"""สร้าง Label สำหรับแต่ละคำ"""
	var label = Label.new()
	
	# ถ้าเป็นคำที่ผิด ให้แสดงคำผิด
	if index in article_data.errors:
		label.text = article_data.errors[index].wrong
		label.add_theme_color_override("font_color", Color.DARK_GRAY)
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# เพิ่ม metadata เพื่อเก็บข้อมูล
		label.set_meta("word_index", index)
		label.set_meta("is_error", true)
		label.set_meta("corrected", false)
		
		# เชื่อมต่อ signal สำหรับคลิก
		label.gui_input.connect(_on_word_clicked.bind(label))
	else:
		label.text = text
		label.add_theme_color_override("font_color", Color.WHITE)
	
	label.add_theme_font_size_override("font_size", 24)
	
	return label

func _on_word_clicked(event: InputEvent, label: Label):
	"""เมื่อคลิกที่คำ"""
	if not is_active:
		return
		
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if label.get_meta("is_error") and not label.get_meta("corrected"):
				_show_correction_panel(label)

func _show_correction_panel(label: Label):
	"""แสดงหน้าต่างแก้ไขคำ"""
	current_error_index = label.get_meta("word_index")
	var error_data = article_data.errors[current_error_index]
	
	question_label.text = "คำที่ถูกต้องของ '" + error_data.wrong + "'"
	answer_edit.text = ""
	correction_panel.visible = true
	answer_edit.grab_focus()
	
	print("[WordCorrection] เปิดหน้าต่างแก้ไข: %s -> ?" % error_data.wrong)

func _on_submit_pressed():
	"""เมื่อกดปุ่มส่งคำตอบ"""
	if current_error_index == -1:
		return
	
	var error_data = article_data.errors[current_error_index]
	var user_answer = answer_edit.text.strip_edges()
	
	if user_answer == error_data.correct:
		# ถูกต้อง
		print("[WordCorrection] ถูกต้อง! %s -> %s" % [error_data.wrong, error_data.correct])
		_mark_word_corrected(current_error_index)
		errors_found += 1
		_update_progress()
		
		correction_panel.visible = false
		current_error_index = -1
		
		# เช็คว่าแก้ครบหรือยัง
		if errors_found >= total_errors:
			_complete_minigame()
	else:
		# ผิด - แสดงข้อความ
		print("[WordCorrection] ผิด! ตอบ: %s (ควรเป็น: %s)" % [user_answer, error_data.correct])
		question_label.text = "ไม่ถูกต้อง ลองใหม่อีกครั้ง '" + error_data.wrong + "'"
		answer_edit.text = ""

func _on_cancel_pressed():
	"""เมื่อกดปุ่มยกเลิก"""
	correction_panel.visible = false
	current_error_index = -1
	print("[WordCorrection] ยกเลิกการแก้ไข")

func _mark_word_corrected(index: int):
	"""ทำเครื่องหมายว่าคำนี้แก้ไขแล้ว"""
	for label in word_labels:
		if label.has_meta("word_index") and label.get_meta("word_index") == index:
			label.set_meta("corrected", true)
			label.text = article_data.errors[index].correct
			label.add_theme_color_override("font_color", Color.SEA_GREEN)
			break

func _update_progress():
	"""อัปเดตความคืบหน้า"""
	progress_label.text = "พบคำผิด: %d / %d" % [errors_found, total_errors]
	
	if errors_found >= total_errors:
		instruction_label.text = "สำเร็จ!"
		instruction_label.modulate = Color.GREEN
	else:
		instruction_label.modulate = Color.WHITE

func _complete_minigame():
	"""จบมินิเกม"""
	print("[WordCorrection] มินิเกมเสร็จสิ้น!")
	is_active = false
	
	# แสดงข้อความเสร็จ 1 วินาที
	await get_tree().create_timer(3.0).timeout
	
	# ปลดล็อคผู้เล่น
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	
	# ส่งสัญญาณว่าเสร็จแล้ว
	completed.emit()
	print("[WordCorrection] ส่งสัญญาณ 'completed'")
