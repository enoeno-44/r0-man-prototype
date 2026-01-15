extends CanvasLayer

@onready var time_label = $TopRight/VBoxContainer/TimeLabel
@onready var date_label = $TopRight/VBoxContainer/DateLabel  # ต้องสร้างใน scene

func _ready():
	# เชื่อมสัญญาณ
	DayManager.day_changed.connect(_on_day_changed)
	_update_date_label()

func _process(_delta):
	var h = TimeManager.hour
	var m = TimeManager.minute
	time_label.text = "%02d:%02d" % [h, m]

func _update_date_label():
	"""อัปเดตวันที่"""
	if date_label:
		date_label.text = DayManager.get_current_date_text()

func _on_day_changed(_new_day: int, _date_text: String):
	"""เมื่อเปลี่ยนวัน"""
	_update_date_label()
