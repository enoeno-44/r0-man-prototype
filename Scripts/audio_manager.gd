# AutoLoad: AudioManager
extends Node

signal bgm_changed(bgm_name: String)
signal sfx_played(sfx_name: String)

const SETTINGS_FILE_PATH = "user://audio_settings.save"

# Audio players
var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8

# Volume settings (0.0 - 1.0)
var master_volume: float = 1.0
var bgm_volume: float = 0.7
var sfx_volume: float = 0.8

# BGM state
var current_bgm: String = ""
var bgm_library: Dictionary = {}
var is_bgm_paused: bool = false

# SFX library
var sfx_library: Dictionary = {}

func _ready():
	_create_audio_players()
	_load_audio_library()
	_load_audio_settings()  # โหลดการตั้งค่าเสียงแยกต่างหาก
	_apply_volume_settings()

func _create_audio_players():
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "BGM"
	add_child(bgm_player)
	
	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_%d" % i
		sfx_player.bus = "SFX"
		add_child(sfx_player)
		sfx_players.append(sfx_player)

func _load_audio_library():
	_register_bgm("main_theme", "res://Resources/Music/Hidden Notes [ZDeahsrmtIA].mp3")
	
	_register_sfx("ui_click", "res://Resources/SFX/select_1.wav")
	_register_sfx("quest_complete", "res://Resources/SFX/coin_4.wav")
	_register_sfx("dialogue_beep", "")
	_register_sfx("transition", "")
	_register_sfx("error", "")
	_register_sfx("qte_success", "res://Resources/SFX/coin.wav")
	_register_sfx("qte_fail", "res://Resources/SFX/hurt.wav")

func _register_bgm(bgm_name: String, path: String):
	if ResourceLoader.exists(path):
		bgm_library[bgm_name] = load(path)
	else:
		push_warning("[AudioManager] BGM not found: %s" % path)

func _register_sfx(sfx_name: String, path: String):
	if ResourceLoader.exists(path):
		sfx_library[sfx_name] = load(path)
	else:
		push_warning("[AudioManager] SFX not found: %s" % path)

# Play BGM with fade in/out transition
func play_bgm(bgm_name: String, fade_duration: float = 1.0):
	if bgm_name == current_bgm and bgm_player.playing:
		return
	
	if bgm_name not in bgm_library:
		push_warning("[AudioManager] BGM '%s' not found!" % bgm_name)
		return
	
	if bgm_player.playing:
		await _fade_out_bgm(fade_duration * 0.5)
	
	bgm_player.stream = bgm_library[bgm_name]
	current_bgm = bgm_name
	bgm_player.play()
	_fade_in_bgm(fade_duration)
	bgm_changed.emit(bgm_name)

func stop_bgm(fade_duration: float = 1.0):
	if bgm_player.playing:
		await _fade_out_bgm(fade_duration)
		bgm_player.stop()
		current_bgm = ""

func pause_bgm():
	if bgm_player.playing:
		bgm_player.stream_paused = true
		is_bgm_paused = true

func resume_bgm():
	if is_bgm_paused:
		bgm_player.stream_paused = false
		is_bgm_paused = false

func _fade_out_bgm(duration: float):
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", -80.0, duration)
	await tween.finished

func _fade_in_bgm(duration: float):
	bgm_player.volume_db = -80.0
	var target_volume = _calculate_volume_db(bgm_volume * master_volume)
	var tween = create_tween()
	tween.tween_property(bgm_player, "volume_db", target_volume, duration)

func play_sfx(sfx_name: String, volume_scale: float = 1.0):
	if sfx_name not in sfx_library:
		push_warning("[AudioManager] SFX '%s' not found!" % sfx_name)
		return
	
	var player = _get_available_sfx_player()
	if not player:
		push_warning("[AudioManager] All SFX players are busy!")
		return
	
	player.stream = sfx_library[sfx_name]
	player.volume_db = _calculate_volume_db(sfx_volume * master_volume * volume_scale)
	player.play()
	sfx_played.emit(sfx_name)

func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	return null

func stop_all_sfx():
	for player in sfx_players:
		player.stop()

func set_master_volume(value: float):
	master_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()
	_save_audio_settings()

func set_bgm_volume(value: float):
	bgm_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()
	_save_audio_settings()

func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()
	_save_audio_settings()

# Apply volume settings to all audio players
func _apply_volume_settings():
	if bgm_player:
		bgm_player.volume_db = _calculate_volume_db(bgm_volume * master_volume)
	
	for player in sfx_players:
		if not player.playing:  # ไม่ปรับเสียงที่กำลังเล่นอยู่
			player.volume_db = _calculate_volume_db(sfx_volume * master_volume)

# คำนวณ volume_db แบบเดียวกันทั้งหมด
func _calculate_volume_db(linear_value: float) -> float:
	if linear_value <= 0.0:
		return -80.0
	# ใช้ exponential curve สำหรับการรับรู้เสียงที่เป็นธรรมชาติ
	var adjusted = pow(linear_value, 3.0)
	return linear_to_db(adjusted)

# บันทึกการตั้งค่าเสียงแยกจาก save game
func _save_audio_settings():
	var settings_data = {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume
	}
	
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings_data)
		file.close()
		print("[AudioManager] บันทึกการตั้งค่าเสียง - BGM: %d%%, SFX: %d%%" % [int(bgm_volume * 100), int(sfx_volume * 100)])
	else:
		push_warning("[AudioManager] ไม่สามารถบันทึกการตั้งค่าเสียงได้!")

# โหลดการตั้งค่าเสียงแยกจาก save game
func _load_audio_settings():
	if not FileAccess.file_exists(SETTINGS_FILE_PATH):
		print("[AudioManager] ใช้ค่าเสียงเริ่มต้น")
		return
	
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if file:
		var settings_data = file.get_var()
		file.close()
		
		if "master_volume" in settings_data:
			master_volume = settings_data.master_volume
		if "bgm_volume" in settings_data:
			bgm_volume = settings_data.bgm_volume
		if "sfx_volume" in settings_data:
			sfx_volume = settings_data.sfx_volume
		
		print("[AudioManager] โหลดการตั้งค่าเสียง - BGM: %d%%, SFX: %d%%" % [int(bgm_volume * 100), int(sfx_volume * 100)])
	else:
		push_warning("[AudioManager] ไม่สามารถอ่านการตั้งค่าเสียงได้!")

# สำหรับ save game (เก็บเฉพาะเพลงที่กำลังเล่น)
func get_save_data() -> Dictionary:
	return {
		"current_bgm": current_bgm
	}

# สำหรับ load game (โหลดเฉพาะเพลงที่กำลังเล่น)
func load_save_data(data: Dictionary):
	# การตั้งค่าเสียงถูกโหลดแยกแล้วใน _ready()
	if "current_bgm" in data and data.current_bgm != "":
		play_bgm(data.current_bgm, 0.5)
