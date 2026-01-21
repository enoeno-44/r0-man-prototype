# AutoLoad: TransitionManager
# transition_manager.gd
extends CanvasLayer

@onready var fade_rect: ColorRect
@onready var chapter_label: Label
@onready var date_label: Label

@export var fade_duration: float = 0.8
@export var text_display_duration: float = 1.8
@export var text_fade_duration: float = 0.5

var is_transitioning: bool = false

func _ready():
	layer = 90
	_create_ui()
	call_deferred("_connect_signals")
	
	await get_tree().process_frame
	opening_fade_in()

func _create_ui():
	fade_rect = ColorRect.new()
	fade_rect.name = "FadeRect"
	fade_rect.color = Color.BLACK
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade_rect)
	
	# Label สำหรับ Chapter (ตัวใหญ่)
	chapter_label = Label.new()
	chapter_label.name = "ChapterLabel"
	chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(chapter_label)
	
	# Label สำหรับวันที่ (ตัวเล็ก)
	date_label = Label.new()
	date_label.name = "DateLabel"
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	date_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(date_label)
	
	fade_rect.modulate.a = 0.0
	chapter_label.modulate.a = 0.0
	date_label.modulate.a = 0.0
	
	get_tree().root.size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()

func _connect_signals():
	if DayManager:
		DayManager.day_transition_started.connect(_on_day_transition_started)

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	if fade_rect:
		fade_rect.size = viewport_size
		fade_rect.position = Vector2.ZERO
	
	if chapter_label:
		# Chapter อยู่ตรงกลาง ตัวใหญ่
		chapter_label.size = viewport_size
		chapter_label.position = Vector2.ZERO
		var chapter_font_size = int(viewport_size.y / 12)  # ตัวใหญ่
		chapter_label.add_theme_font_size_override("font_size", chapter_font_size)
	
	if date_label:
		# วันที่อยู่ด้านล่าง Chapter ตัวเล็ก
		date_label.size = viewport_size
		date_label.position = Vector2(0, viewport_size.y * 0.58)  # เลื่อนลงมาหน่อย
		var date_font_size = int(viewport_size.y / 20)  # ตัวเล็ก
		date_label.add_theme_font_size_override("font_size", date_font_size)

func opening_fade_in():
	fade_rect.modulate.a = 1.0
	
	_hide_hud()
	_freeze_player(true)
	
	await _show_date_text_for_opening()
	
	if has_node("/root/SystemDialogueManager"):
		var day = DayManager.get_current_day()
		var lines = SystemDialogueManager._get_dialogue_for_day(day)
		SystemDialogueManager.show_dialogue(lines)
		
		await SystemDialogueManager.dialogue_finished
		
		var tween = create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 1.5)
		tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await tween.finished
		
		_freeze_player(false)

func _show_date_text_for_opening():
	if not DayManager:
		return
	
	# แสดง Chapter และวันที่แยกกัน
	chapter_label.text = DayManager.get_current_chapter()
	date_label.text = DayManager.get_current_date_text()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(chapter_label, "modulate:a", 1.0, text_fade_duration)
	tween.tween_property(date_label, "modulate:a", 1.0, text_fade_duration)
	await tween.finished
	
	await get_tree().create_timer(text_display_duration).timeout
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(chapter_label, "modulate:a", 0.0, text_fade_duration)
	tween.tween_property(date_label, "modulate:a", 0.0, text_fade_duration)
	await tween.finished

func _hide_hud():
	var hud_nodes = get_tree().get_nodes_in_group("hud")
	for hud in hud_nodes:
		hud.hide()

func _freeze_player(freeze: bool):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not freeze)
		if player.has_method("set_can_move"):
			player.set_can_move(not freeze)
		if freeze and player.has_method("force_idle"):
			player.force_idle()
			
func _on_day_transition_started():
	if is_transitioning:
		return
	
	is_transitioning = true
	
	await _fade_out()
	await _show_date_text()
	
	if has_node("/root/SystemDialogueManager"):
		var day = DayManager.get_current_day()
		var lines = SystemDialogueManager._get_dialogue_for_day(day)
		SystemDialogueManager.show_dialogue(lines)
		
		await SystemDialogueManager.dialogue_finished
	
	await _fade_in()
	is_transitioning = false

func _fade_out():
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, fade_duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

func _show_date_text():
	if not DayManager:
		return
	
	# แสดง Chapter และวันที่แยกกัน
	chapter_label.text = DayManager.get_current_chapter()
	date_label.text = DayManager.get_current_date_text()
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(chapter_label, "modulate:a", 1.0, text_fade_duration)
	tween.tween_property(date_label, "modulate:a", 1.0, text_fade_duration)
	await tween.finished
	
	await get_tree().create_timer(text_display_duration).timeout
	
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(chapter_label, "modulate:a", 0.0, text_fade_duration)
	tween.tween_property(date_label, "modulate:a", 0.0, text_fade_duration)
	await tween.finished

func _fade_in():
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, fade_duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func custom_fade_out(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished

func custom_fade_in(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

func show_text(text: String, duration: float = 2.0):
	chapter_label.text = text
	date_label.text = ""
	
	var tween = create_tween()
	tween.tween_property(chapter_label, "modulate:a", 1.0, 0.5)
	await tween.finished
	
	await get_tree().create_timer(duration).timeout
	
	tween = create_tween()
	tween.tween_property(chapter_label, "modulate:a", 0.0, 0.5)
	await tween.finished

func transition_to_scene(scene_path: String, fade_out_duration: float = 0.8, fade_in_duration: float = 0.8):
	await custom_fade_out(fade_out_duration)
	get_tree().change_scene_to_file(scene_path)
	await custom_fade_in(fade_in_duration)

func _exit_tree():
	if DayManager and DayManager.day_transition_started.is_connected(_on_day_transition_started):
		DayManager.day_transition_started.disconnect(_on_day_transition_started)
