extends CanvasLayer

@onready var time_label = $TopRight/VBoxContainer/TimeLabel

func _process(_delta):
	var h = TimeManager.hour
	var m = TimeManager.minute
	time_label.text = "%02d:%02d" % [h, m]
