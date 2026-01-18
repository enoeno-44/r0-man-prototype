# AutoLoad: EndGameManager
# จัดการฉากจบเกม: ตัดดำทันที → Credits → กด Space เพื่อออก
extends CanvasLayer

signal ending_started
signal ending_finished

@onready var black_screen: ColorRect
@onready var credits_label: RichTextLabel
@onready var exit_label: Label

@export var credits_scroll_speed: float = 40.0
@export var credits_text: String = """
[center][b]THE END[/b][/center]

[center]--- CREDITS ---[/center]

[center]Game Design & Programming[/center]
[center]Your Name[/center]

[center]Art & Animation[/center]
[center]Your Name[/center]

[center]Story & Dialogue[/center]
[center]Your Name[/center]

[center]Special Thanks[/center]
[center]Godot Engine Community[/center]

[center]Made with Godot 4.3[/center]

[center]--- Thank You for Playing ---[/center]
"""

var is_ending: bool = false
var can_exit: bool = false

func _ready():
	layer = 100
	_create_ui()
	hide()

func _process(_delta):
	# กด Space เพื่อออกจากเกม
	if can_exit and Input.is_action_just_pressed("ui_accept"):
		print("[EndGame] กด Space - ออกจากเกม")
		get_tree().quit()

func _create_ui():
	"""สร้าง UI สำหรับจบเกม"""
	# จอดำ (ตัดทันที ไม่ Fade)
	black_screen = ColorRect.new()
	black_screen.name = "BlackScreen"
	black_screen.color = Color.BLACK
	black_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black_screen)
	
	# Credits
	credits_label = RichTextLabel.new()
	credits_label.name = "CreditsLabel"
	credits_label.bbcode_enabled = true
	credits_label.fit_content = true
	credits_label.scroll_active = false
	credits_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credits_label)
	
	# ตกแต่ง Credits
	credits_label.add_theme_font_size_override("normal_font_size", 24)
	credits_label.add_theme_font_size_override("bold_font_size", 32)
	credits_label.add_theme_color_override("default_color", Color.WHITE)
	credits_label.add_theme_constant_override("outline_size", 4)
	credits_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	
	# Label "กด Space เพื่อออก"
	exit_label = Label.new()
	exit_label.name = "ExitLabel"
	exit_label.text = "[ กด SPACE เพื่อออกจากเกม ]"
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	exit_label.add_theme_font_size_override("font_size", 20)
	exit_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	exit_label.add_theme_constant_override("outline_size", 4)
	exit_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	exit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exit_label)
	
	# ซ่อนทั้งหมด
	black_screen.hide()
	credits_label.hide()
	exit_label.hide()
	
	get_tree().root.size_changed.connect(_update_ui_positions)
	_update_ui_positions()

func _update_ui_positions():
	"""ปรับขนาด UI ตามหน้าจอ"""
	var viewport_size = get_viewport().get_visible_rect().size
	
	if black_screen:
		black_screen.size = viewport_size
		black_screen.position = Vector2.ZERO
	
	if credits_label:
		credits_label.size = viewport_size
		credits_label.position = Vector2(0, viewport_size.y)
	
	if exit_label:
		exit_label.size = viewport_size
		exit_label.position = Vector2(0, 0)

func start_ending():
	"""เริ่มฉากจบเกม"""
	if is_ending:
		return
	
	is_ending = true
	show()
	
	print("[EndGame] === เริ่มฉากจบเกม ===")
	ending_started.emit()
	
	# หยุดทุกอย่าง
	_freeze_everything()
	
	# ตัดเป็นภาพดำทันที (ไม่ Fade)
	_show_black_screen()
	
	# ซ่อน HUD
	_hide_hud()
	
	# รอสักครู่
	await get_tree().create_timer(0.5).timeout
	
	# แสดง Credits
	await _show_credits()
	
	# เปิดให้กด Space ออกได้
	_enable_exit()

func _freeze_everything():
	"""หยุดทุกอย่างในเกม"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		if player.has_method("set_can_move"):
			player.set_can_move(false)
	
	if has_node("/root/TimeManager"):
		TimeManager.set_process(false)
	
	print("[EndGame] หยุดทุกอย่าง")

func _hide_hud():
	"""ซ่อน HUD"""
	if has_node("/root/HUDManager"):
		var hud = get_node("/root/HUDManager")
		hud.hide()
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			hud.hide()
	
	print("[EndGame] ซ่อน HUD")

func _show_black_screen():
	"""แสดงจอดำทันที (ไม่ Fade)"""
	print("[EndGame] ตัดเป็นภาพดำ")
	black_screen.show()

func _show_credits():
	"""แสดง Credits (เลื่อนขึ้น)"""
	print("[EndGame] กำลังแสดง Credits...")
	
	credits_label.text = credits_text
	credits_label.show()
	
	var viewport_size = get_viewport().get_visible_rect().size
	var start_y = viewport_size.y
	var end_y = -credits_label.get_content_height() - 100
	
	credits_label.position.y = start_y
	
	# คำนวณระยะเวลา
	var distance = start_y - end_y
	var duration = distance / credits_scroll_speed
	
	print("[EndGame] เลื่อน Credits (%.1f วินาที)" % duration)
	
	var tween = create_tween()
	tween.tween_property(credits_label, "position:y", end_y, duration)
	await tween.finished
	
	# รอ 2 วินาที
	await get_tree().create_timer(2.0).timeout
	
	print("[EndGame] ✓ Credits จบ")

func _enable_exit():
	"""เปิดให้กด Space ออกได้"""
	print("[EndGame] กด Space เพื่อออกจากเกม")
	
	can_exit = true
	exit_label.show()
	
	# Pulse animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(exit_label, "modulate:a", 0.4, 0.8)
	tween.tween_property(exit_label, "modulate:a", 1.0, 0.8)
	
	ending_finished.emit()

# ========================================
# Helper Functions
# ========================================

func set_credits_text(text: String):
	"""กำหนดข้อความ Credits ใหม่"""
	credits_text = text

func set_scroll_speed(speed: float):
	"""ปรับความเร็วเลื่อน Credits"""
	credits_scroll_speed = speed
