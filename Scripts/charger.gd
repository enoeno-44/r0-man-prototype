# charger.gd
extends Area2D

@onready var label = $Label

var player_in_range: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	DayManager.all_quests_completed.connect(_update_label)
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
		print("[Charger] กำลังเปลี่ยนวัน...")
		label.hide()
		SaveManager.save_game()
		DayManager.advance_to_next_day()
	else:
		var completed = DayManager.get_completed_count()
		var total = DayManager.get_total_quests_today()
		print("[Charger] ทำภารกิจไม่ครบ: %d/%d" % [completed, total])

func _update_label():
	if DayManager.can_advance_day():
		label.text = "กด E เพื่อผ่านไปวันถัดไป"
	else:
		var completed = DayManager.get_completed_count()
		var total = DayManager.get_total_quests_today()
		label.text = "ทำภารกิจ: %d/%d" % [completed, total]
	
	if player_in_range and DayManager.can_advance_day():
		label.show()

func _on_day_changed(_new_day: int, _date_text: String):
	print("[Charger] เข้าสู่วันที่ %d" % _new_day)
	_update_label()
