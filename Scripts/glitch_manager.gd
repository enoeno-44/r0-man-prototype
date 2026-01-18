# AutoLoad: GlitchManager
# glitch_manager.gd
extends Node

var glitch_shader: Shader
var glitch_material: ShaderMaterial

var affected_nodes: Array = []

@export var glitch_intensity: float = 0.0
@export var pixel_size: float = 4.0
@export var color_corruption: float = 0.3

func _ready():
	glitch_shader = load("res://Resources/Shaders/glitch_effect.gdshader")
	
	if not glitch_shader:
		return
	
	glitch_material = ShaderMaterial.new()
	glitch_material.shader = glitch_shader
	_update_shader_params()
	
	if DayManager:
		DayManager.day_changed.connect(_on_day_changed)
		
		await get_tree().process_frame
		if DayManager.get_current_day() == 6:
			activate_glitch()

func _on_day_changed(new_day: int, _date_text: String):
	if new_day == 6:
		activate_glitch()
	else:
		deactivate_glitch()

func activate_glitch():
	_apply_shader_to_glitchable_nodes()
	
	if affected_nodes.is_empty():
		return
	
	var tween = create_tween()
	tween.tween_property(self, "glitch_intensity", 0.5, 2.0)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_update_shader_params)

func deactivate_glitch():
	var tween = create_tween()
	tween.tween_property(self, "glitch_intensity", 0.0, 1.5)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		_remove_shader_from_all()
		_update_shader_params()
	)

func _apply_shader_to_glitchable_nodes():
	affected_nodes.clear()
	
	var glitchable_nodes = get_tree().get_nodes_in_group("glitchable")
	
	if glitchable_nodes.is_empty():
		return
	
	for node in glitchable_nodes:
		if _is_valid_glitch_node(node):
			_apply_shader_to_node(node)
			affected_nodes.append(node)

func _is_valid_glitch_node(node) -> bool:
	return node is Sprite2D or node is AnimatedSprite2D or node.is_class("TileMapLayer")

func _apply_shader_to_node(node):
	if not node:
		return
	
	var mat = ShaderMaterial.new()
	mat.shader = glitch_shader
	
	mat.set_shader_parameter("glitch_strength", glitch_intensity)
	mat.set_shader_parameter("color_shift_amount", glitch_intensity * 0.5)
	mat.set_shader_parameter("scan_line_speed", 1.0)
	mat.set_shader_parameter("distortion_speed", 0.5)
	mat.set_shader_parameter("pixel_size", pixel_size)
	mat.set_shader_parameter("color_corruption", color_corruption)
	
	node.material = mat

func _remove_shader_from_all():
	for node in affected_nodes:
		if is_instance_valid(node):
			node.material = null
	
	affected_nodes.clear()

func _update_shader_params():
	for node in affected_nodes:
		if is_instance_valid(node) and node.material is ShaderMaterial:
			node.material.set_shader_parameter("glitch_strength", glitch_intensity)
			node.material.set_shader_parameter("color_shift_amount", glitch_intensity * 0.5)
			node.material.set_shader_parameter("pixel_size", pixel_size)
			node.material.set_shader_parameter("color_corruption", color_corruption)

func set_glitch_intensity(value: float):
	glitch_intensity = clamp(value, 0.0, 1.0)
	_update_shader_params()

func set_pixel_size(value: float):
	pixel_size = clamp(value, 1.0, 32.0)
	_update_shader_params()

func set_color_corruption(value: float):
	color_corruption = clamp(value, 0.0, 1.0)
	_update_shader_params()

func pulse_glitch(duration: float = 0.5, max_intensity: float = 0.8):
	var original = glitch_intensity
	
	var tween = create_tween()
	tween.tween_property(self, "glitch_intensity", max_intensity, duration * 0.3)
	tween.tween_property(self, "glitch_intensity", original, duration * 0.7)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	tween.step_finished.connect(func(_idx):
		_update_shader_params()
	)

func add_node_to_glitch(node: Node):
	if not _is_valid_glitch_node(node):
		return
	
	if node in affected_nodes:
		return
	
	_apply_shader_to_node(node)
	affected_nodes.append(node)

func remove_node_from_glitch(node: Node):
	if node not in affected_nodes:
		return
	
	if is_instance_valid(node):
		node.material = null
	
	affected_nodes.erase(node)
