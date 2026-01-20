# word_correction_minigame.gd
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
@onready var submit_button = $Panel/CorrectionPanel/VBoxContainer/SubmitButton

# ข้อมูลบทความ (คำผิด : คำถูก)
var article_data = {
	"words": [
		"ลูกรัก", "ตั้งแต่ลูกไปทำงาน ", "บ้านก็ดูเงียบลงมาก ", "ดอกไม้ที่ลูกเคยปลูกไว้หน้าบ้าน ", "แม่ยังคอยดูแลมันอยู่เหมือนเดิม ",
		"ทุกครั้งที่มันออกดอก ", "แม่ก็อยากให้ลูกได้กลับมาดูด้วยตาตัวเอง", "ว่าสิ่งที่ลูกตั้งใจปลูกไว้นั้นสวยแค่ไหน", 
		"แม่รู้ว่าลูกเหนื่อยกับงาน ","แม่ไม่โกรธที่ติดต่อกันได้น้อยลง","บางวันโทรไปไม่มีคนรับ", "ก็อดเป็นห่วงไม่ได้",
		"ได้แต่คิดว่าลูกสบายดีหรือเปล่า", "ถ้าวันไหนลูกเหนื่อยหรือท้อ", "อยากให้รู้ว่ายังมีบ้านหลังนี้", "และพ่อกับแม่ที่รอฟังอยู่เสมอ",
		"เมื่อมีเวลา กลับมาหาดอกไม้ที่ลูกปลูกไว้บ้างนะ"
	],
	"errors": {
		4: {"wrong": "ตลาด", "correct": "ตลาต"},  # คำที่ 4 ผิด
		10: {"wrong": "สด", "correct": "สต"},      # คำที่ 10 ผิด
		19: {"wrong": "ผักสด", "correct": "ผักสต"}  # คำที่ 19 ผิด
	}
}

var corrections_needed: int = 3
var current_corrections: int = 0
var is_active: bool = false
var selected_word_index: int = -1

func _ready():
	hide()
	submit_button.pressed.connect(_on_submit_pressed)
	
	# ถ้าอยู่ที่ root (ทดสอบเดี่ยว)
	if get_parent() == get_tree().root:
		start_minigame()

func start_minigame():
	"""เริ่มมินิเกม"""
	print("[WordCorrection] เริ่มมินิเกม")
	show()
	is_active = true
	current_corrections = 0
	selected_word_index = -1
	_build_article()
	_update_ui()

func _build_article():
	"""สร้างบทความด้วย RichTextLabel"""
	# ลบ child เก่าทั้งหมด
	for child in article_container.get_children():
		child.queue_free()
	
	# สร้าง RichTextLabel เดียว
	var rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.fit_content = true
	rich_text.scroll_active = false
	rich_text.custom_minimum_size = Vector2(550, 0)
	rich_text.add_theme_font_size_override("normal_font_size", 18)
	rich_text.add_theme_font_size_override("bold_font_size", 18)
	
	# สร้างข้อความ BBCode
	var bbcode_text = ""
	
	for i in range(article_data.words.size()):
		var word = article_data.words[i]
		
		# ถ้าเป็นคำผิด
		if i in article_data.errors:
			word = article_data.errors[i].wrong
			# ใช้ BBCode สีแดง + คลิกได้
			bbcode_text += "[color=white][url=%d]%s[/url][/color]" % [i, word]
		else:
			bbcode_text += word + ""
	
	rich_text.text = bbcode_text
	
	# เชื่อมต่อ signal สำหรับคลิก
	rich_text.meta_clicked.connect(_on_word_meta_clicked)
	
	article_container.add_child(rich_text)

func _on_word_meta_clicked(meta):
	"""เมื่อคลิกที่คำ (ใช้กับ RichTextLabel)"""
	if not is_active:
		return
	
	var word_index = int(meta)
	
	# เช็คว่าเป็นคำผิดหรือไม่
	if word_index in article_data.errors:
		selected_word_index = word_index
		var wrong_word = article_data.errors[word_index].wrong
		question_label.text = "คำที่เลือก: '%s'\nพิมพ์คำที่ถูกต้อง:" % wrong_word
		answer_edit.text = ""
		correction_panel.show()
		answer_edit.grab_focus()
		print("[WordCorrection] เลือกคำที่ %d: %s" % [word_index, wrong_word])

func _on_submit_pressed():
	"""เมื่อกดปุ่มส่งคำตอบ"""
	if selected_word_index == -1:
		return
	
	var user_answer = answer_edit.text.strip_edges()
	var correct_answer = article_data.errors[selected_word_index].correct
	
	print("[WordCorrection] ตรวจคำตอบ: '%s' vs '%s'" % [user_answer, correct_answer])
	
	if user_answer == correct_answer:
		print("[WordCorrection] ✓ ถูกต้อง!")
		current_corrections += 1
		
		# ลบคำผิดออกจาก dict
		article_data.errors.erase(selected_word_index)
		
		# อัปเดตบทความ
		_build_article()
		_update_ui()
		
		correction_panel.hide()
		selected_word_index = -1
		
		# เช็คว่าครบหรือยัง
		if current_corrections >= corrections_needed:
			_complete_minigame()
	else:
		print("[WordCorrection] ✗ ผิด!")
		answer_edit.add_theme_color_override("font_color", Color.RED)
		await get_tree().create_timer(0.5).timeout
		answer_edit.remove_theme_color_override("font_color")

func _update_ui():
	"""อัปเดต UI"""
	progress_label.text = "ความคืบหน้า: %d/%d คำ" % [current_corrections, corrections_needed]
	
	if current_corrections >= corrections_needed:
		instruction_label.text = "เยี่ยมมาก! แก้ไขครบทุกคำแล้ว!"
		instruction_label.add_theme_color_override("font_color", Color.GREEN)

func _complete_minigame():
	"""จบมินิเกม"""
	print("[WordCorrection] มินิเกมเสร็จสิ้น!")
	is_active = false
	
	# แสดงข้อความเสร็จ 2 วินาที
	await get_tree().create_timer(2.0).timeout
	
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
