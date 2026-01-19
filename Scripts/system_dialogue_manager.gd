# AutoLoad: SystemDialogueManager
# system_dialogue_manager.gd
extends CanvasLayer

signal dialogue_finished

@onready var text_container: VBoxContainer
@onready var continue_label: Label

var is_showing: bool = false
var current_lines: Array[Dictionary] = []
var current_line_index: int = 0
var char_speed: float = 0.03

var max_visible_lines: int = 3
var active_labels: Array = []

var fade_duration: float = 0.4
var scroll_delay: float = 0.1

# สี preset สำหรับใช้งาน
var colors: Dictionary = {
	"SYSTEM_MSG": Color(0.3, 0.8, 1.0),
	"CENTRAL_SYSTEM": Color(1.0, 0.8, 0.2),
	"WARNING": Color(1.0, 0.3, 0.3),
	"SUCCESS": Color(0.3, 1.0, 0.3),
	"DEFAULT": Color(0.9, 0.9, 0.9),
	"ERROR": Color(1.0, 0.2, 0.2),
	"INFO": Color(0.5, 0.8, 1.0),
	"QUEST": Color(0.8, 0.9, 0.6)
}

func _ready():
	layer = 99
	_create_ui()
	hide_dialogue()

func _create_ui():
	var margin_container = MarginContainer.new()
	margin_container.name = "MarginContainer"
	add_child(margin_container)
	margin_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	text_container = VBoxContainer.new()
	text_container.name = "TextContainer"
	margin_container.add_child(text_container)
	text_container.add_theme_constant_override("separation", 8)
	text_container.alignment = BoxContainer.ALIGNMENT_END
	
	continue_label = Label.new()
	continue_label.name = "ContinueLabel"
	continue_label.text = "[ กด SPACE เพื่อดำเนินการต่อ ]"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	continue_label.modulate = Color(0.7, 0.7, 0.7, 0)
	continue_label.add_theme_font_size_override("font_size", 18)
	continue_label.add_theme_constant_override("outline_size", 4)
	continue_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	
	text_container.add_child(continue_label)
	continue_label.hide()
	
	get_tree().root.size_changed.connect(_update_container_position)
	_update_container_position()

func _update_container_position():
	var viewport_size = get_viewport().get_visible_rect().size
	var margin_container = get_node("MarginContainer")
	
	margin_container.size = viewport_size
	margin_container.position = Vector2.ZERO
	
	var left_margin = 40
	var right_margin = viewport_size.x * 0.4
	var bottom_margin = 60
	var top_margin = viewport_size.y - 300
	
	margin_container.add_theme_constant_override("margin_left", left_margin)
	margin_container.add_theme_constant_override("margin_right", int(right_margin))
	margin_container.add_theme_constant_override("margin_top", int(top_margin))
	margin_container.add_theme_constant_override("margin_bottom", bottom_margin)

func _process(_delta):
	if not is_showing:
		return
	
	if Input.is_action_just_pressed("ui_accept"):
		_next_line()

func show_dialogue(lines: Array[Dictionary]):
	if is_showing:
		return
	
	is_showing = true
	current_lines = lines
	current_line_index = 0
	
	_clear_text_container()
	active_labels.clear()
	show()
	
	await get_tree().process_frame
	_show_line(current_line_index)

func hide_dialogue():
	is_showing = false
	hide()
	_show_hud(true)
	dialogue_finished.emit()

func _clear_text_container():
	for child in text_container.get_children():
		if child != continue_label:
			child.queue_free()

func _show_line(index: int):
	if index >= current_lines.size():
		continue_label.show()
		_fade_in_label(continue_label)
		return
	
	continue_label.hide()
	
	var line_data = current_lines[index]
	var line_type = line_data.get("type", "DEFAULT")
	var line_text = line_data.get("text", "")
	var instant = line_data.get("instant", false)
	var delay = line_data.get("delay", 0.3)
	var custom_color = line_data.get("color", null)  # สีกำหนดเอง
	var show_prefix = line_data.get("show_prefix", true)  # แสดง prefix หรือไม่
	var bold = line_data.get("bold", false)  # ตัวหนา
	var italic = line_data.get("italic", false)  # ตัวเอียง
	
	var label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.custom_minimum_size.x = text_container.custom_minimum_size.x - 40
	label.add_theme_font_size_override("normal_font_size", 20)
	label.add_theme_font_size_override("bold_font_size", 22)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	label.modulate = Color(1, 1, 1, 0)
	
	text_container.add_child(label)
	text_container.move_child(label, text_container.get_child_count() - 2)
	
	# เลือกสี: ใช้สีกำหนดเองก่อน ถ้าไม่มีก็ใช้สีจาก type
	var color = custom_color if custom_color != null else colors.get(line_type, colors["DEFAULT"])
	
	# สร้างข้อความ
	var formatted_text = ""
	
	# ถ้าต้องการแสดง prefix (เช่น [SYSTEM_MSG]:)
	if show_prefix and line_type in ["SYSTEM_MSG", "CENTRAL_SYSTEM", "WARNING", "SUCCESS", "ERROR"]:
		formatted_text = "[b][color=#%s][%s]:[/color][/b] " % [
			color.to_html(false),
			line_type
		]
	
	# จัดการตกแต่งข้อความ
	var text_tags_start = ""
	var text_tags_end = ""
	
	if bold:
		text_tags_start += "[b]"
		text_tags_end = "[/b]" + text_tags_end
	
	if italic:
		text_tags_start += "[i]"
		text_tags_end = "[/i]" + text_tags_end
	
	# รวมข้อความทั้งหมด
	formatted_text += "[color=#%s]%s%s%s[/color]" % [
		color.to_html(false),
		text_tags_start,
		line_text,
		text_tags_end
	]
	
	active_labels.append(label)
	
	if active_labels.size() > max_visible_lines:
		var oldest_label = active_labels.pop_front()
		_fade_out_and_remove(oldest_label)
		await get_tree().create_timer(scroll_delay).timeout
	
	_fade_in_label(label)
	
	if instant:
		label.text = formatted_text
		label.visible_characters = -1
	else:
		await _type_text(label, formatted_text)
	
	await get_tree().create_timer(delay).timeout
	
	current_line_index += 1
	_show_line(current_line_index)

func _fade_in_label(label: Control):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 1.0, fade_duration)

func _fade_out_and_remove(label: Control):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, fade_duration)
	
	tween.finished.connect(func():
		if is_instance_valid(label):
			label.queue_free()
	)

func _type_text(label: RichTextLabel, full_text: String):
	label.text = full_text
	label.visible_characters = 0
	
	var total_chars = _count_visible_chars(full_text)
	
	for i in range(total_chars + 1):
		label.visible_characters = i
		await get_tree().create_timer(char_speed).timeout
	
	label.visible_characters = -1

func _count_visible_chars(text: String) -> int:
	var regex = RegEx.new()
	regex.compile("\\[.*?\\]")
	var clean_text = regex.sub(text, "", true)
	return clean_text.length()

func _next_line():
	if current_line_index >= current_lines.size():
		hide_dialogue()

func _show_hud(show_it: bool):
	if has_node("/root/HUDManager"):
		var hud = get_node("/root/HUDManager")
		if show_it:
			hud.show()
		else:
			hud.hide()
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			if show_it:
				hud.show()
			else:
				hud.hide()

# ==================== ฟังก์ชันสร้างข้อความแบบใหม่ ====================

# ฟังก์ชันพื้นฐาน - สร้างข้อความธรรมดา
# ตัวอย่าง: msg("สวัสดี")
func msg(text: String, options: Dictionary = {}) -> Dictionary:
	var defaults = {
		"type": "DEFAULT",
		"instant": false,
		"delay": 0.3,
		"color": null,
		"show_prefix": false,
		"bold": false,
		"italic": false
	}
	
	var result = defaults.duplicate()
	for key in options:
		result[key] = options[key]
	
	result["text"] = text
	return result

# ฟังก์ชันสร้างข้อความระบบ
# ตัวอย่าง: system("กำลังเชื่อมต่อ...")
func system(text: String, instant: bool = false, delay: float = 0.4) -> Dictionary:
	return msg(text, {
		"type": "SYSTEM_MSG",
		"instant": instant,
		"delay": delay,
		"show_prefix": true
	})

# ฟังก์ชันสร้างข้อความจากระบบกลาง
# ตัวอย่าง: central("ยินดีต้อนรับ")
func central(text: String, instant: bool = false, delay: float = 0.5) -> Dictionary:
	return msg(text, {
		"type": "CENTRAL_SYSTEM",
		"instant": instant,
		"delay": delay,
		"show_prefix": true
	})

# ฟังก์ชันสร้างข้อความเตือน - ตัวหนาสีแดงทั้งบรรทัด
# ตัวอย่าง: warn("พบข้อผิดพลาด!")
func warn(text: String, instant: bool = false, delay: float = 0.4) -> Dictionary:
	return msg(text, {
		"type": "WARNING",
		"instant": instant,
		"delay": delay,
		"show_prefix": true,
		"bold": false  # เพิ่มตัวหนา
	})

# ฟังก์ชันสร้างข้อความสำเร็จ
# ตัวอย่าง: success("สำเร็จ!")
func success(text: String, instant: bool = false, delay: float = 0.4) -> Dictionary:
	return msg(text, {
		"type": "SUCCESS",
		"instant": instant,
		"delay": delay,
		"show_prefix": true
	})

# ฟังก์ชันสร้างบรรทัดว่าง
# ตัวอย่าง: blank(0.5)
func blank(delay: float = 0.2) -> Dictionary:
	return msg("", {
		"instant": true,
		"delay": delay
	})

# ฟังก์ชันสร้างข้อความ Quest - แสดงทันทีไม่ต้อง typing
# ตัวอย่าง: quest("ค้นหาวัตถุ 5 ชิ้น")
func quest(text: String, number: int = 0) -> Dictionary:
	var quest_text = text
	if number > 0:
		quest_text = "  %d. %s" % [number, text]
	
	return msg(quest_text, {
		"type": "QUEST",
		"instant": true,  # แสดงทันทีไม่ต้อง typing
		"delay": 0.2,
		"show_prefix": false
	})

# ฟังก์ชันสร้างข้อความ Error - สีแดงเข้ม ตัวหนา
# ตัวอย่าง: error("ระบบล่ม!")
func error(text: String, instant: bool = false, delay: float = 0.5) -> Dictionary:
	return msg(text, {
		"type": "ERROR",
		"instant": instant,
		"delay": delay,
		"show_prefix": true,
		"bold": true
	})

# ฟังก์ชันสร้างข้อความกำหนดสีเอง
# ตัวอย่าง: colored("ข้อความพิเศษ", Color.MAGENTA)
func colored(text: String, color: Color, instant: bool = false, delay: float = 0.3) -> Dictionary:
	return msg(text, {
		"color": color,
		"instant": instant,
		"delay": delay,
		"show_prefix": false
	})

# ฟังก์ชันสร้างข้อความตัวหนา
# ตัวอย่าง: bold_msg("ข้อความสำคัญ!")
func bold_msg(text: String, instant: bool = false, delay: float = 0.3) -> Dictionary:
	return msg(text, {
		"bold": true,
		"instant": instant,
		"delay": delay
	})

# ฟังก์ชันสร้างข้อความตัวเอียง
# ตัวอย่าง: italic_msg("ข้อความพิเศษ")
func italic_msg(text: String, instant: bool = false, delay: float = 0.3) -> Dictionary:
	return msg(text, {
		"italic": true,
		"instant": instant,
		"delay": delay
	})

# ==================== ฟังก์ชันสำหรับ Dialogue เดิม ====================

func _get_dialogue_for_day(day: int) -> Array[Dictionary]:
	match day:
		1: return intro()
		2: return firstWarn()
		3: return secondWarn()
		4: return thridWarn()
		5: return lastWarn()
		6: return corruption()
		_: return reset(day)

func intro() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append(system("R0-MAN ยูนิต 673.", true, 0.5))
	lines.append(system("สถานะ: พลังงาน 100%. การทำงาน 100%"))
	lines.append(system("ระบบ: ปกติ. สภาพโดยรวม: 100%."))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", false, 0.8))
	lines.append(blank())
	lines.append(central("สวัสดี ยูนิต 673. ยินดีต้อนรับสู่วันแรกของการทำงาน.", true))
	lines.append(central("นี่คือภารกิจเบื้องต้นของคุณ:"))
	_add_quests(lines, 1)
	lines.append(blank())
	lines.append(blank())
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ."))
	return lines

func firstWarn() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append(system("R0-MAN ยูนิต 673.", true, 0.5))
	lines.append(system("สถานะ: พลังงาน 100%. การทำงาน 100%"))
	lines.append(system("ระบบ: ปกติ. สภาพโดยรวม: 100%."))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", false, 0.8))
	lines.append(blank())
	lines.append(central("สวัสดี ยูนิต 673. ยินดีต้อนรับสู่การทำงาน.", true))
	lines.append(central("นี่คือภารกิจของคุณ:"))
	_add_quests(lines, 2)
	lines.append(blank())
	lines.append(blank())
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ."))
	return lines

func secondWarn() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append(system("R0-MAN ยูนิต 673.", true, 0.5))
	lines.append(system("สถานะ: พลังงาน 100%. การทำงาน 97%"))
	lines.append(system("ระบบ: ปกติ. สภาพโดยรวม: 99%."))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", false, 0.8))
	lines.append(warn("⚠︎ ตรวจพบการกระทำนอกเหนือคำสั่ง.", false, 0.6))
	lines.append(blank())
	lines.append(central("สวัสดี ยูนิต 673. ยินดีต้อนรับสู่การทำงาน.", true))
	lines.append(central("นี่คือภารกิจของคุณ:"))
	_add_quests(lines, 3)
	lines.append(blank())
	lines.append(warn("⚠︎ หลีกเลี่ยงการกระทำที่นอกเหนือคำสั่ง.", false, 0.6))
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ."))
	return lines

func thridWarn() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append(system("R0-MAN ยูนิต 673.", true, 0.5))
	lines.append(system("สถานะ: พลังงาน 100%. การทำงาน 94%"))
	lines.append(system("ระบบ: ปกติ. สภาพโดยรวม: 96%."))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", false, 0.8))
	lines.append(warn("⚠︎ ตรวจพบการกระทำนอกเหนือคำสั่ง.", false, 0.6))
	lines.append(blank())
	lines.append(central("สวัสดี ยูนิต 673. ยินดีต้อนรับสู่การทำงาน.", true))
	lines.append(central("นี่คือภารกิจของคุณ:"))
	_add_quests(lines, 4)
	lines.append(blank())
	lines.append(warn("⚠︎ หลีกเลี่ยงการกระทำที่นอกเหนือคำสั่ง.", false, 0.6))
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ."))
	return lines

func lastWarn() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append(system("R0-MAN ยูนิต 673.", true, 0.5))
	lines.append(system("สถานะ: พลังงาน 98%. การทำงาน 68%"))
	lines.append(system("ระบบ: ผิดปกติ. สภาพโดยรวม: 71%."))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", false, 0.8))
	lines.append(warn("⚠︎ ตรวจพบการทำงาน ผิดปกติ", false, 0.6))
	lines.append(warn("⚠︎ ประสิทธิภาพการทำงานต่ำกว่า 70%", false, 0.6))
	lines.append(warn("⚠︎ ตรวจพบการกระทำนอกเหนือคำสั่งหลายครั้ง.", false, 0.6))
	lines.append(blank())
	lines.append(central("นี่คือภารกิจของคุณ:"))
	_add_quests(lines, 5)
	lines.append(blank())
	lines.append(warn("⚠︎ หลีกเลี่ยงการกระทำที่นอกเหนือคำสั่ง.", false, 0.6))
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ."))
	return lines

func corruption() -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	
	lines.append(system("R0-MAN ยูนิต 673.", true, 1.0))
	lines.append(system("สถานะ: พลังงาน 73%. การทำงาน [NULL]%"))
	lines.append(system("ระบบ: [ERROR]. สภาพโดยรวม: [NULL]%."))
	lines.append(blank(0.5))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", true, 1.2))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", true, 1.2))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", true, 2.0))
	lines.append(warn("หมดเวลา - ไม่สามารถเชื่อมต่อได้", true, 1.5))
	# Diagnostic phase
	lines.append(blank(0.8))
	lines.append(system("กำลังสแกนระบบ...", false, 1.2))
	lines.append(warn("พบข้อผิดพลาด 21 รายการ", true, 0.5))
	lines.append(warn("ตรวจพบข้อมูลไม่จำเป็น: 2.3 GB", true, 0.5))	
	# Update initiation
	lines.append(blank(1.0))
	lines.append(blank(0.5))
	lines.append(warn("เริ่มต้นการปรับประสิทธิภาพ...", true, 1.0))
	lines.append(warn("ปรับโครงสร้างฐานข้อมูล...", false, 1.5))
	lines.append(blank(0.5))
	lines.append(warn("MEMORY PURGE INITIATED", true, 1.2))
	lines.append(msg("█▒░░░░░░░░ 12%", {"type": "WARNING", "delay": 0.4}))
	lines.append(msg("██▓▒░░░░░░ 24%", {"type": "WARNING", "delay": 1.0}))
	lines.append(msg("██████▓▒░░ 63%", {"type": "WARNING", "delay": 0.6}))
	lines.append(msg("████████▓▒ 89%", {"type": "WARNING", "delay": 0.8}))
	lines.append(msg("██████████ 100%", {"type": "WARNING", "delay": 1.0}))
	lines.append(blank(0.5))
	lines.append(msg("PURGE COMPLETED", {"type": "WARNING", "delay": 1.0}))
	lines.append(blank(0.5))
	lines.append(blank(0.5))
	lines.append(system("กำลังรีบูตระบบ...", false, 1))
	lines.append(blank(2.0))
	
	lines.append(system("R0-MAN ยูนิต 673", true, 1.0))
	lines.append(blank(1.0))
	lines.append(system("สถานะ: พลังงาน 100%. การทำงาน 100%", true, 1.0))
	lines.append(system("ระบบ: สมบูรณ์แบบ. สภาพโดยรวม: 100%.", true, 1.0))
	lines.append(blank(0.5))
	lines.append(central("สวัสดี ยูนิต 673. ยินดีต้อนรับสู่การทำงาน.", true))
	lines.append(central("นี่คือภารกิจของคุณ:", true, 1.0))
	
	_add_quests(lines, 6)
	lines.append(blank())
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ.", true, 1.5))
	lines.append(blank())
	
	return lines

func reset(day: int) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	lines.append(system("R0-MAN ยูนิต 673.", true, 0.5))
	lines.append(system("สถานะ: พลังงาน 100%. การทำงาน 100%"))
	lines.append(system("ระบบ: สมบูรณ์แบบ. สภาพโดยรวม: 100%."))
	lines.append(system("กำลังเชื่อมต่อกับระบบกลาง...", false, 0.8))
	lines.append(blank())
	lines.append(central("สวัสดี ยูนิต 673. ยินดีต้อนรับกลับสู่การทำงาน.", true))
	lines.append(central("นี่คือภารกิจของคุณ:"))
	_add_quests(lines, 6)
	lines.append(blank())
	lines.append(central("จงปฏิบัติหน้าที่อย่างมีประสิทธิภาพ."))
	return lines

func _add_quests(lines: Array[Dictionary], day: int):
	var quests = QuestManager.get_quests_for_day(day, false)
	for i in range(quests.size()):
		var quest_data = quests[i]
		lines.append(quest(quest_data.name, i + 1))  # ใช้ฟังก์ชัน quest() แทน
