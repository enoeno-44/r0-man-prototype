# map_boundary_warning.gd
extends Area2D

@export var warning_message: String = "คุณไม่สามารถออกนอกพื้นที่ได้"
@export var warning_duration: float = 2.0

var warning_label: Label = null
var is_showing: bool = false

func _ready():
	collision_layer = 4
	collision_mask = 3
	body_entered.connect(_on_body_entered)
	_setup_warning_ui()

func _setup_warning_ui():
	var canvas = CanvasLayer.new()
	canvas.name = "BoundaryWarning"
	canvas.layer = 100
	add_child(canvas)
	
	warning_label = Label.new()
	warning_label.text = warning_message
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	warning_label.add_theme_font_size_override("font_size", 36)
	warning_label.add_theme_color_override("font_color", Color.RED)
	warning_label.add_theme_constant_override("outline_size", 10)
	warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	warning_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(warning_label)
	warning_label.hide()

func _on_body_entered(body: Node2D):
	if body is CharacterBody2D and (body.is_in_group("player") or body.name == "Player"):
		_show_warning()

func _show_warning():
	if is_showing:
		return
	
	is_showing = true
	warning_label.modulate.a = 0.0
	warning_label.show()
	
	var tween = create_tween()
	tween.tween_property(warning_label, "modulate:a", 1.0, 0.3)
	await get_tree().create_timer(warning_duration).timeout
	
	tween = create_tween()
	tween.tween_property(warning_label, "modulate:a", 0.0, 0.3)
	await tween.finished
	
	warning_label.hide()
	is_showing = false
