# AutoLoad: TimeManager
# จัดการเวลาในเกม
extends Node

signal time_changed(hour: int, minute: int)

var hour: float = 6.0
var minute: float = 0.0

@export var time_scale := 1.2

func _process(delta):
	minute += delta * time_scale
	
	if minute >= 60:
		var hours_passed = int(minute / 60)
		hour += hours_passed
		minute = int(minute) % 60
		
		# หยุดที่ 20:00
		if hour > 20:
			hour = 20
			minute = 0
		
		time_changed.emit(int(hour), int(minute))
