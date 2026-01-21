# simple_walkin_npc.gd
extends CharacterBody2D

@export var waypoints: Array[Vector2] = []
@export var move_speed: float = 50.0
@export var wait_time_at_waypoint: float = 2.0
@export var initial_wait_time: float = 30.0

@export_group("Label Settings")
@export var show_label_on_approach: bool = true
@export var label_text: String = "สวัสดี!"
@export var detection_radius: float = 100.0
@export var label_offset_y: float = -40.0
@export var fade_duration: float = 0.3

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

var current_waypoint_index: int = 0
var is_waiting: bool = false
var is_moving: bool = false
var player_in_range: bool = false
var last_direction: Vector2 = Vector2.DOWN
var has_shown_label: bool = false

var label: Label
var detection_area: Area2D

func _ready():
	_create_label()
	
	if show_label_on_approach:
		_create_detection_area()
	
	await get_tree().create_timer(initial_wait_time).timeout
	
	if waypoints.size() > 0:
		is_moving = true

func _create_label():
	if has_node("Label"):
		label = $Label
	else:
		label = Label.new()
		label.name = "Label"
		add_child(label)
	
	label.text = label_text
	label.position = Vector2(0, label_offset_y)
	label.modulate.a = 0.0
	label.visible = false
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_font_size_override("font_size", 16)
	
	label.z_index = 100

func _create_detection_area():
	detection_area = Area2D.new()
	detection_area.name = "DetectionArea"
	detection_area.collision_layer = 0
	detection_area.collision_mask = 2
	add_child(detection_area)
	
	var collision_shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = detection_radius
	collision_shape.shape = circle
	detection_area.add_child(collision_shape)
	
	detection_area.body_entered.connect(_on_player_entered)
	detection_area.body_exited.connect(_on_player_exited)

func _physics_process(delta):
	if waypoints.size() == 0 or not is_moving or is_waiting:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	var target = waypoints[current_waypoint_index]
	var direction = (target - global_position).normalized()
	
	if global_position.distance_to(target) < 5:
		_reach_waypoint()
		return
	
	velocity = direction * move_speed
	last_direction = direction
	_play_walk_animation(direction)
	move_and_slide()

func _reach_waypoint():
	current_waypoint_index += 1
	
	if current_waypoint_index >= waypoints.size():
		is_moving = false
		velocity = Vector2.ZERO
		_play_idle_animation()
		return
	
	is_waiting = true
	velocity = Vector2.ZERO
	_play_idle_animation()
	
	await get_tree().create_timer(wait_time_at_waypoint).timeout
	is_waiting = false

func _on_player_entered(body):
	if (body.is_in_group("player") or body.name == "Player") and not has_shown_label:
		player_in_range = true
		has_shown_label = true
		_fade_in_label()

func _on_player_exited(body):
	if body.is_in_group("player") or body.name == "Player":
		player_in_range = false
		_fade_out_label()

func _fade_in_label():
	if not label:
		return
	
	label.visible = true
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, fade_duration)

func _fade_out_label():
	if not label:
		return
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, fade_duration)
	await tween.finished
	label.visible = false

func _play_walk_animation(dir: Vector2):
	if not sprite or not sprite.sprite_frames:
		return
	
	var frames = sprite.sprite_frames
	
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0 and frames.has_animation("walk_right"):
			sprite.play("walk_right")
		elif dir.x < 0 and frames.has_animation("walk_left"):
			sprite.play("walk_left")
	else:
		if dir.y > 0 and frames.has_animation("walk_down"):
			sprite.play("walk_down")
		elif dir.y < 0 and frames.has_animation("walk_up"):
			sprite.play("walk_up")

func _play_idle_animation():
	if not sprite or not sprite.sprite_frames:
		return
	
	var frames = sprite.sprite_frames
	
	if abs(last_direction.x) > abs(last_direction.y):
		if last_direction.x > 0 and frames.has_animation("idle_right"):
			sprite.play("idle_right")
		elif last_direction.x < 0 and frames.has_animation("idle_left"):
			sprite.play("idle_left")
	else:
		if last_direction.y > 0 and frames.has_animation("idle_down"):
			sprite.play("idle_down")
		elif last_direction.y < 0 and frames.has_animation("idle_up"):
			sprite.play("idle_up")
