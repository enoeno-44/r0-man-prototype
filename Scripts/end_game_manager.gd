# AutoLoad: EndGameManager
# end_game_manager.gd
extends CanvasLayer

signal ending_started
signal ending_finished

@onready var black_screen: ColorRect
@onready var credits_label: RichTextLabel
@onready var exit_label: Label

const CREDITS_FONT_REGULAR = preload("res://Resources/Fonts/GoogleSans-Regular.ttf")
const CREDITS_FONT_BOLD = preload("res://Resources/Fonts/GoogleSans-Bold.ttf")

@export var credits_scroll_speed: float = 35.0
@export var credits_text: String = """
[center][b]THE END[/b][/center]

[center]- Game Design & Programming -[/center]
[center]นายจักรพรรดิ หงษ์ชากรณ์[/center]
[center]นายรัฐภูมิ นามบัวน้อย[/center]

[center]- Art & Animation -[/center]
[center]นายจักรพรรดิ หงษ์ชากรณ์[/center]
[center]นายรัฐภูมิ นามบัวน้อย[/center]

[center]- Story & Dialogue -[/center]
[center]นายจักรพรรดิ หงษ์ชากรณ์[/center]

[center]- Resources -[/center]
[center]Modern Exteriors - RPG Tileset By LimeZu[/center]
[center]กีต้าดอกกระเจียวบาน - Tiktok @chanapat_jen[/center]

[center]- Special Thanks -[/center]
[center]Godot Engine Community[/center]
[center]Claude AI[/center]
[center]GEMINI AI[/center]
[center]Chat GPT[/center]

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
	if can_exit and Input.is_action_just_pressed("ui_accept"):
		get_tree().quit()

func _create_ui():
	black_screen = ColorRect.new()
	black_screen.name = "BlackScreen"
	black_screen.color = Color.BLACK
	black_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(black_screen)
	
	credits_label = RichTextLabel.new()
	credits_label.name = "CreditsLabel"
	credits_label.bbcode_enabled = true
	credits_label.fit_content = true
	credits_label.scroll_active = false
	credits_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(credits_label)
	if CREDITS_FONT_REGULAR:
		credits_label.add_theme_font_override("normal_font", CREDITS_FONT_REGULAR)
	
	if CREDITS_FONT_BOLD:
		credits_label.add_theme_font_override("bold_font", CREDITS_FONT_BOLD)
		
	credits_label.add_theme_font_size_override("normal_font_size", 24)
	credits_label.add_theme_font_size_override("bold_font_size", 32)
	credits_label.add_theme_color_override("default_color", Color.WHITE)
	credits_label.add_theme_constant_override("outline_size", 4)
	credits_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	
	exit_label = Label.new()
	exit_label.name = "ExitLabel"
	exit_label.text = "[ กด SPACE เพื่อออกจากเกม ]"
	exit_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exit_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	if CREDITS_FONT_REGULAR:
		exit_label.add_theme_font_override("font", CREDITS_FONT_REGULAR)
	exit_label.add_theme_font_size_override("font_size", 20)
	exit_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	exit_label.add_theme_constant_override("outline_size", 4)
	exit_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	exit_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(exit_label)
	
	black_screen.hide()
	credits_label.hide()
	exit_label.hide()
	
	get_tree().root.size_changed.connect(_update_ui_positions)
	_update_ui_positions()

func _update_ui_positions():
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
	if is_ending:
		return
	
	is_ending = true
	show()
	
	ending_started.emit()
	
	_freeze_everything()
	_show_black_screen()
	_hide_hud()
	
	await get_tree().create_timer(3).timeout
	await _show_credits()
	
	_enable_exit()

func _freeze_everything():
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(false)
		if player.has_method("set_can_move"):
			player.set_can_move(false)
		if player.has_method("force_idle"):
			player.force_idle()
			
	if has_node("/root/TimeManager"):
		TimeManager.set_process(false)

func _hide_hud():
	if has_node("/root/HUDManager"):
		var hud = get_node("/root/HUDManager")
		hud.hide()
	else:
		var hud_nodes = get_tree().get_nodes_in_group("hud")
		for hud in hud_nodes:
			hud.hide()

func _show_black_screen():
	black_screen.show()

func _show_credits():
	credits_label.text = credits_text
	credits_label.show()
	
	var viewport_size = get_viewport().get_visible_rect().size
	var start_y = viewport_size.y
	var end_y = -credits_label.get_content_height() - 100
	
	credits_label.position.y = start_y
	
	var distance = start_y - end_y
	var duration = distance / credits_scroll_speed
	
	var tween = create_tween()
	tween.tween_property(credits_label, "position:y", end_y, duration)
	await tween.finished
	
	await get_tree().create_timer(2.0).timeout

func _enable_exit():
	can_exit = true
	exit_label.show()
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(exit_label, "modulate:a", 0.4, 0.8)
	tween.tween_property(exit_label, "modulate:a", 1.0, 0.8)
	
	ending_finished.emit()

func set_credits_text(text: String):
	credits_text = text

func set_scroll_speed(speed: float):
	credits_scroll_speed = speed
