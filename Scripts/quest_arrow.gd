# quest_arrow.gd
extends Node2D

@export var arrow_distance: float = 60.0
@export var arrow_color: Color = Color(1, 0.8, 0, 1)
@export var pulse_speed: float = 2.0
@export var pulse_scale: float = 0.2

var player: CharacterBody2D
var current_target: Area2D = null
var quest_areas: Array[Area2D] = []

@onready var arrow_sprite: Polygon2D = _get_or_create_arrow()
@export var completion_text: String = "กลับสู่แท่นชาร์จ"
@export var completion_label: Label = null
@export var wasd_label: Label = null
var _blink_tween: Tween

var time: float = 0.0

func _ready():
	z_index = 100
	wasd_label.visible = true
	_start_blink_effect()
	
	if not arrow_sprite:
		return
	
	_create_arrow_shape()
	arrow_sprite.color = arrow_color
	
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	_register_quest_areas()
	_update_target()
	
	QuestManager.quest_completed.connect(_on_quest_completed)
	DayManager.all_quests_completed.connect(_on_all_quests_completed)
	DayManager.day_changed.connect(_on_day_changed)

func _process(delta):
	if not player or not current_target:
		visible = false
		return
	
	if DayManager.can_advance_day():
		visible = false
		return
	
	var hide_area = current_target.get_node_or_null("ArrowHideArea")
	if hide_area and hide_area is Area2D:
		if player in hide_area.get_overlapping_bodies():
			visible = false
			return
	
	visible = true
	time += delta
	
	global_position = player.global_position
	
	var direction = (current_target.global_position - player.global_position).normalized()
	rotation = direction.angle()
	
	var pulse = 1.0 + sin(time * pulse_speed) * pulse_scale
	scale = Vector2(pulse, pulse)

func _get_or_create_arrow() -> Polygon2D:
	var arrow = get_node_or_null("Arrow")
	
	if not arrow:
		arrow = Polygon2D.new()
		arrow.name = "Arrow"
		add_child(arrow)
	
	return arrow

func _create_arrow_shape():
	var points = PackedVector2Array([
		Vector2(arrow_distance + 15, 0),
		Vector2(arrow_distance, -8),
		Vector2(arrow_distance + 5, 0),
		Vector2(arrow_distance, 8),
	])
	arrow_sprite.polygon = points

func _register_quest_areas():
	quest_areas.clear()
	var all_areas = get_tree().get_nodes_in_group("quest_area")
	var current_day = DayManager.get_current_day()
	
	for area in all_areas:
		if area is Area2D and area.has_method("_is_active") and area.quest_day == current_day:
			quest_areas.append(area)

func _update_target():
	current_target = null
	
	if DayManager.can_advance_day():
		visible = false
		return
	
	for area in quest_areas:
		if not QuestManager.is_quest_done(area.quest_id):
			current_target = area
			visible = true
			return
	
	visible = false

func _on_quest_completed(_quest_id: String):
	await get_tree().create_timer(0.5).timeout
	_update_target()
	if wasd_label:
		_stop_blink_effect()
		wasd_label.visible = false

func _on_all_quests_completed():
	visible = false
	current_target = null
	if completion_label:
		completion_label.text = completion_text
		completion_label.visible = true
		_start_blink_effect()

func _on_day_changed(_new_day: int, _date_text: String):
	await get_tree().create_timer(0.3).timeout
	_register_quest_areas()
	_update_target()
	if completion_label:
		_stop_blink_effect()
		completion_label.visible = false

func set_arrow_color(color: Color):
	arrow_color = color
	if arrow_sprite:
		arrow_sprite.color = color

func set_arrow_distance(distance: float):
	arrow_distance = distance
	_create_arrow_shape()
	
func _start_blink_effect():
	if _blink_tween:
		_blink_tween.kill()
	
	_blink_tween = create_tween().set_loops()
	
	_blink_tween.tween_property(completion_label, "modulate:a", 0.0, 0.8)
	_blink_tween.tween_property(completion_label, "modulate:a", 1.0, 0.8)
	_blink_tween.tween_property(wasd_label, "modulate:a", 0.0, 0.8)
	_blink_tween.tween_property(wasd_label, "modulate:a", 1.0, 0.8)

func _stop_blink_effect():
	if _blink_tween:
		_blink_tween.kill()
	
	if completion_label:
		completion_label.modulate.a = 1.0
	if wasd_label:
		wasd_label.modulate.a = 1.0
