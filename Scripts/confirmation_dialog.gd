# confirmation_dialog.gd
extends CanvasLayer

signal confirmed
signal cancelled
signal extra_action(action_name: String)

@onready var message_label = $CenterContainer/Panel/VBoxContainer/MessageLabel
@onready var confirm_button = $CenterContainer/Panel/VBoxContainer/HBoxContainer/ConfirmButton
@onready var cancel_button = $CenterContainer/Panel/VBoxContainer/HBoxContainer/CancelButton
@onready var extra_button = $CenterContainer/Panel/VBoxContainer/HBoxContainer/ExtraButton

func _ready():
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	if extra_button:
		extra_button.pressed.connect(_on_extra_pressed)

func setup(message: String, confirm_text: String = "ตรงลง", cancel_text: String = "ยกเลิก", extra_text: String = ""):
	message_label.text = message
	confirm_button.text = confirm_text
	cancel_button.text = cancel_text
	
	if extra_text != "" and extra_button:
		extra_button.text = extra_text
		extra_button.show()
	elif extra_button:
		extra_button.hide()
	
	cancel_button.grab_focus()

func _on_confirm_pressed():
	AudioManager.play_sfx("ui_click")
	confirmed.emit()
	queue_free()

func _on_cancel_pressed():
	AudioManager.play_sfx("ui_click")
	cancelled.emit()
	queue_free()

func _on_extra_pressed():
	AudioManager.play_sfx("ui_click")
	if extra_button:
		extra_action.emit(extra_button.name)
	queue_free()
