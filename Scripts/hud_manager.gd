# hud_manager.gd
extends CanvasLayer

@onready var time_label = $TopRight/VBoxContainer/TimeLabel
@onready var date_label = $TopRight/VBoxContainer/DateLabel

@onready var item_container = $RightCenter/HBoxContainer
@onready var item1 = $RightCenter/HBoxContainer/item1
@onready var item2 = $RightCenter/HBoxContainer/item2
@onready var item3 = $RightCenter/HBoxContainer/item3

var item_slots: Array = []

func _ready():
	add_to_group("hud")
	DayManager.day_changed.connect(_on_day_changed)
	_update_date_label()
	
	item_slots = [item1, item2, item3]
	
	for slot in item_slots:
		if slot:
			slot.hide()
	
	if has_node("/root/ItemManager"):
		ItemManager.item_added.connect(_on_item_added)
		_refresh_items()

func _process(_delta):
	var h = int(TimeManager.hour)
	var m = int(TimeManager.minute)
	time_label.text = "%02d:%02d" % [h, m]

func _update_date_label():
	if date_label:
		date_label.text = DayManager.get_current_date_text()

func _on_day_changed(_new_day: int, _date_text: String):
	_update_date_label()

func _on_item_added(item_name: String, icon: Texture2D):
	_refresh_items()

func _refresh_items():
	var items = ItemManager.get_items()
	
	for slot in item_slots:
		if slot:
			slot.hide()
	
	for i in range(min(items.size(), item_slots.size())):
		var slot = item_slots[i]
		var item_data = items[i]
		
		if slot:
			if item_data.icon and slot is TextureRect:
				slot.texture = item_data.icon
				slot.show()
			elif slot is Label:
				slot.text = item_data.name
				slot.show()
