extends Area2D

@onready var label = $Label
@onready var sprite = $Sprite2D  # optional

var player_in_range: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	DayManager.all_quests_completed.connect(_on_all_quests_completed)
	DayManager.day_changed.connect(_on_day_changed)
	
	label.hide()
	_update_label()

func _process(_delta):
	if player_in_range and Input.is_action_just_pressed("interact"):
		_try_advance_day()

func _on_body_entered(body):
	if body.name == "Player":
		player_in_range = true
		_update_label()
		if DayManager.can_advance_day():
			label.show()

func _on_body_exited(body):
	if body.name == "Player":
		player_in_range = false
		label.hide()

func _try_advance_day():
	if DayManager.can_advance_day():
		print("[DayTransition] กำลังเปลี่ยนวัน...")
		label.hide()
		DayManager.advance_to_next_day()
	else:
		print("[DayTransition] ยังทำภารกิจไม่ครบ: %d/%d" % [
			DayManager.get_completed_count(),
			DayManager.get_total_quests_today()
		])

func _update_label():
	if DayManager.can_advance_day():
		label.text = "กด E เพื่อผ่านไปวันถัดไป"
	else:
		var completed = DayManager.get_completed_count()
		var total = DayManager.get_total_quests_today()
		label.text = "ทำภารกิจ: %d/%d" % [completed, total]

func _on_all_quests_completed():
	"""เมื่อทำภารกิจครบ"""
	_update_label()
	if player_in_range:
		label.show()

func _on_day_changed(new_day: int, _date_text: String):
	"""เมื่อเปลี่ยนวัน"""
	print("[DayTransition] เข้าสู่วันที่ %d" % new_day)
	_update_label()
