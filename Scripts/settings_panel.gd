# settings_panel.gd
# แนบกับ SettingsPanel (Panel Node)
extends Panel

@onready var bgm_slider = $"VBoxContainer/HBoxContainer Music/MusicSlider"
@onready var sfx_slider = $"VBoxContainer/HBoxContainer SFX/SFXSlider"

@onready var bgm_label = $"VBoxContainer/HBoxContainer Music/MusicLabel"
@onready var sfx_label = $"VBoxContainer/HBoxContainer SFX/SFXLabel"

@onready var back_button = $VBoxContainer/BackButton

func _ready():
	# ตั้งค่า Sliders
	bgm_slider.min_value = 0.0
	bgm_slider.max_value = 1.0
	bgm_slider.step = 0.05
	
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.05
	
	# โหลดค่าปัจจุบัน
	_load_current_settings()
	
	# เชื่อม Signals
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	# หมายเหตุ: Back button จะถูกเชื่อมโดย parent (MainMenu หรือ PauseMenu)

func _load_current_settings():
	"""โหลดค่าเสียงปัจจุบัน"""
	if not has_node("/root/AudioManager"):
		print("[SettingsPanel] ไม่พบ AudioManager!")
		return
	
	# ป้องกันการ trigger signal ขณะตั้งค่าเริ่มต้น
	bgm_slider.value_changed.disconnect(_on_bgm_volume_changed)
	sfx_slider.value_changed.disconnect(_on_sfx_volume_changed)
	
	bgm_slider.value = AudioManager.bgm_volume
	sfx_slider.value = AudioManager.sfx_volume
	
	# เชื่อม signal กลับ
	bgm_slider.value_changed.connect(_on_bgm_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	
	_update_labels()

func _on_bgm_volume_changed(value: float):
	"""เมื่อปรับ BGM Volume"""
	AudioManager.set_bgm_volume(value)
	_update_labels()
	print("[SettingsPanel] BGM Volume: %d%%" % int(value * 100))

func _on_sfx_volume_changed(value: float):
	"""เมื่อปรับ SFX Volume"""
	AudioManager.set_sfx_volume(value)
	_update_labels()
	
	# เล่นเสียงทดสอบ
	AudioManager.play_sfx("ui_click", 0.5)
	print("[SettingsPanel] SFX Volume: %d%%" % int(value * 100))

func _update_labels():
	"""อัปเดตตัวเลขที่แสดง"""
	bgm_label.text = "เสียงเพลง: " + "%d%%" % int(AudioManager.bgm_volume * 100)
	sfx_label.text = "เสียงเอฟเฟค: " + "%d%%" % int(AudioManager.sfx_volume * 100)

# ฟังก์ชันนี้เรียกได้จากภายนอกเมื่อเปิด Panel
func refresh_settings():
	"""รีเฟรชค่าตั้งค่าเมื่อเปิด Panel"""
	_load_current_settings()

# เรียกเมื่อ Panel กลายเป็น visible
func _on_visibility_changed():
	if visible:
		refresh_settings()
