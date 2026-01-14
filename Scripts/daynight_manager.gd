extends Node2D

@onready var day_night = $DayNight

@export var dark_start_hour := 15   # เริ่มมืด
@export var dark_end_hour := 19     # มืดเต็ม
@export var min_light := 0.4        # มืดสุด

func _process(_delta):
	update_light()

func update_light():
	var hour = TimeManager.hour
	var darkness := 0.0

	if hour < dark_start_hour:
		darkness = 0.0
	elif hour < dark_end_hour:
		darkness = float(hour - dark_start_hour) / float(dark_end_hour - dark_start_hour)
	else:
		darkness = 1.2

	var light_value = lerp(1.0, min_light, darkness)
	day_night.color = Color(light_value, light_value, light_value)
