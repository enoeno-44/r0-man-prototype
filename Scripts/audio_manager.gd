# AutoLoad: AudioManager
# audio_manager.gd
extends Node

# ===== SIGNALS =====
signal bgm_changed(bgm_name: String)
signal sfx_played(sfx_name: String)

# ===== AUDIO PLAYERS =====
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8  # จำนวน SFX ที่เล่นพร้อมกันได้

# ===== VOLUME SETTINGS (0.0 - 1.0) =====
var master_volume: float = 1.0
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8

# ===== BGM MANAGEMENT =====
var current_bgm: String = ""
var bgm_library: Dictionary = {}
var is_bgm_paused: bool = false

# ===== SFX LIBRARY =====
var sfx_library: Dictionary = {}

func _ready():
	# สร้าง BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "BGM"  # เชื่อมกับ Audio Bus "BGM"
	add_child(bgm_player)
	
	# สร้าง SFX Players (Pool)
	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_%d" % i
		sfx_player.bus = "SFX"  # เชื่อมกับ Audio Bus "SFX"
		add_child(sfx_player)
		sfx_players.append(sfx_player)
	
	# โหลดเสียงทั้งหมด
	_load_audio_library()
	_load_saved_settings()

	# ตั้งค่าเสียงเริ่มต้น
	_apply_volume_settings()

# ==================== LOAD AUDIO FILES ====================

func _load_audio_library():
	"""โหลดไฟล์เสียงทั้งหมดเข้า Library"""
	
	# โหลด BGM
	_register_bgm("main_theme", "res://Resources/Music/Hidden Notes [ZDeahsrmtIA].mp3")
	#_register_bgm("minigame", "")
	#_register_bgm("ending", "")
	
	# โหลด SFX
	_register_sfx("ui_click", "res://Resources/SFX/select_1.wav")
	_register_sfx("quest_complete", "res://Resources/SFX/coin_4.wav")
	_register_sfx("dialogue_beep", "")
	_register_sfx("transition", "")
	_register_sfx("error", "")
	_register_sfx("qte_success", "res://Resources/SFX/coin.wav")
	_register_sfx("qte_fail", "res://Resources/SFX/hurt.wav")

func _register_bgm(bgm_name: String, path: String):
	"""ลงทะเบียน BGM"""
	if ResourceLoader.exists(path):
		bgm_library[bgm_name] = load(path)
	else:
		push_warning("[AudioManager] BGM not found: %s" % path)

func _register_sfx(sfx_name: String, path: String):
	"""ลงทะเบียน SFX"""
	if ResourceLoader.exists(path):
		sfx_library[sfx_name] = load(path)
	else:
		push_warning("[AudioManager] SFX not found: %s" % path)

# ==================== BGM CONTROL ====================

func play_bgm(bgm_name: String, fade_duration: float = 1.0):
	"""เล่น BGM พร้อม Fade In"""
	if bgm_name == current_bgm and bgm_player.playing:
		return  # เล่นอยู่แล้ว ไม่ต้องทำอะไร
	
	if bgm_name not in bgm_library:
		push_warning("[AudioManager] BGM '%s' not found!" % bgm_name)
		return
	
	# Fade Out BGM เก่า
	if bgm_player.playing:
		await _fade_out_bgm(fade_duration * 0.5)
	
	# เปลี่ยนเพลงใหม่
	bgm_player.stream = bgm_library[bgm_name]
	current_bgm = bgm_name
	bgm_player.play()
	
	# Fade In BGM ใหม่
	_fade_in_bgm(fade_duration)
	
	bgm_changed.emit(bgm_name)
	print("[AudioManager] Playing BGM: %s" % bgm_name)

func stop_bgm(fade_duration: float = 1.0):
	"""หยุด BGM พร้อม Fade Out"""
	if bgm_player.playing:
		await _fade_out_bgm(fade_duration)
		bgm_player.stop()
		current_bgm = ""
		print("[AudioManager] BGM Stopped")

func pause_bgm():
	"""หยุด BGM ชั่วคราว (ไม่ Fade)"""
	if bgm_player.playing:
		bgm_player.stream_paused = true
		is_bgm_paused = true
		print("[AudioManager] BGM Paused")

func resume_bgm():
	"""เล่น BGM ต่อ"""
	if is_bgm_paused:
		bgm_player.stream_paused = false
		is_bgm_paused = false
		print("[AudioManager] BGM Resumed")

func _fade_out_bgm(duration: float):
	"""Fade Out BGM"""
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, duration)
	await tween.finished

func _fade_in_bgm(duration: float):
	"""Fade In BGM"""
	bgm_player.volume_db = -80.0
	var target_volume = linear_to_db(bgm_volume * master_volume)
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", target_volume, duration)

# ==================== SFX CONTROL ====================

func play_sfx(sfx_name: String, volume_scale: float = 1.0):
	"""เล่น SFX"""
	if sfx_name not in sfx_library:
		push_warning("[AudioManager] SFX '%s' not found!" % sfx_name)
		return
	
	# หา SFX Player ว่าง
	var player = _get_available_sfx_player()
	if not player:
		push_warning("[AudioManager] All SFX players are busy!")
		return
	
	player.stream = sfx_library[sfx_name]
	player.volume_db = linear_to_db(sfx_volume * master_volume * volume_scale)
	player.play()
	
	sfx_played.emit(sfx_name)

func _get_available_sfx_player() -> AudioStreamPlayer:
	"""หา SFX Player ที่ว่าง"""
	for player in sfx_players:
		if not player.playing:
			return player
	return null  # ถ้าไม่มีว่าง

func stop_all_sfx():
	"""หยุด SFX ทั้งหมด"""
	for player in sfx_players:
		player.stop()

# ==================== VOLUME CONTROL ====================

func set_master_volume(value: float):
	"""ตั้งระดับเสียงหลัก (0.0 - 1.0)"""
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()

func set_bgm_volume(value: float):
	"""ตั้งระดับเสียง BGM (0.0 - 1.0)"""
	bgm_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()
	_save_settings() 

func set_sfx_volume(value: float):
	"""ตั้งระดับเสียง SFX (0.0 - 1.0)"""
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()
	_save_settings() 

func _apply_volume_settings():
	"""ปรับเสียงตาม Settings แบบ Logarithmic"""
	if bgm_player:
		# ใช้ exponential scale เพื่อให้การรับรู้เป็นธรรมชาติ
		var linear_volume = _volume_slider_to_linear(bgm_volume * master_volume)
		bgm_player.volume_db = linear_to_db(linear_volume)
	for player in sfx_players:
		var linear_volume = _volume_slider_to_linear(sfx_volume * master_volume)
		player.volume_db = linear_to_db(linear_volume)
		
func _volume_slider_to_linear(slider_value: float) -> float:
	"""แปลงค่า slider (0-1) เป็น linear volume ที่รับรู้ได้ดีกว่า"""
	if slider_value <= 0.0:
		return 0.0
		# ใช้ exponential curve (กำลัง 3 ทำให้การเปลี่ยนแปลงนุ่มนวลขึ้น)
	return pow(slider_value, 3.0)

# ==================== SAVE/LOAD ====================

func get_save_data() -> Dictionary:
	"""ส่งออกข้อมูลสำหรับบันทึก"""
	return {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"current_bgm": current_bgm
	}
func load_save_data(data: Dictionary):
	"""โหลดข้อมูลที่บันทึกไว้"""
	if "master_volume" in data:
		master_volume = data.master_volume
	if "bgm_volume" in data:
		bgm_volume = data.bgm_volume
	if "sfx_volume" in data:
		sfx_volume = data.sfx_volume
	
	_apply_volume_settings()
	
	# เล่น BGM ที่เคยเล่นอยู่ (ถ้ามี)
	if "current_bgm" in data and data.current_bgm != "":
		play_bgm(data.current_bgm, 0.5)

func _save_settings():
	"""บันทึก audio settings แยกจาก save game"""
	const SETTINGS_PATH = "user://audio_settings.save"
	var data = {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume
		}

func _load_saved_settings():
	"""โหลด audio settings ที่บันทึกไว้"""
	const SETTINGS_PATH = "user://audio_settings.save"
	if FileAccess.file_exists(SETTINGS_PATH):
		var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			file.close()
			
			if "master_volume" in data:
				master_volume = data.master_volume
			if "bgm_volume" in data:
				bgm_volume = data.bgm_volume
			if "sfx_volume" in data:
				sfx_volume = data.sfx_volume
				
			print("[AudioManager] โหลด Audio Settings สำเร็จ: BGM=%.1f%%, SFX=%.1f%%" % [bgm_volume*100, sfx_volume*100])
