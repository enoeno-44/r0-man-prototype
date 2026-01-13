extends CanvasLayer

@onready var fade_rect := $ColorRect

func _ready():
	fade_rect.modulate.a = 2
	fade_in()

func fade_in():
	var tween = create_tween()
	tween.tween_property(
		fade_rect,
		"modulate:a",
		0.0,
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
