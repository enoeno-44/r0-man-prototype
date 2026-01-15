extends Node

var hour: float = 6
var minute: float = 0

@export var time_scale := 0.5


func _process(delta):
	advance_time(delta)

func advance_time(delta):
	minute += delta * time_scale

	if minute >= 60:
		hour += int(minute / 60)
		minute = int(minute) % 60

		if hour > 20:
			hour = 20
			minute = 0

		emit_signal("time_changed", hour, minute)
