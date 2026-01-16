# แสดงเวลาและวันที่บน HUD
extends CanvasLayer

@onready var time_label = $TopRight/VBoxContainer/TimeLabel
@onready var date_label = $TopRight/VBoxContainer/DateLabel

func _ready():
	DayManager.day_changed.connect(_on_day_changed)
	_update_date_label()

func _process(_delta):
	var h = int(TimeManager.hour)
	var m = int(TimeManager.minute)
	time_label.text = "%02d:%02d" % [h, m]

func _update_date_label():
	if date_label:
		date_label.text = DayManager.get_current_date_text()

func _on_day_changed(_new_day: int, _date_text: String):
	_update_date_label()
