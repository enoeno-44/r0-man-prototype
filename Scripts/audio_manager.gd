# AutoLoad: AudioManager
extends Node

signal bgm_changed(bgm_name: String)
signal sfx_played(sfx_name: String)

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
	var target_volume = linear_to_db(bgm_volume * master_volume)
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
	player.volume_db = linear_to_db(sfx_volume * master_volume * volume_scale)
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

func set_bgm_volume(value: float):
	bgm_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()

func set_sfx_volume(value: float):
	sfx_volume = clamp(value, 0.0, 1.0)
	_apply_volume_settings()

# Apply logarithmic volume scaling for natural perception
func _apply_volume_settings():
	if bgm_player:
		var linear_volume = _volume_slider_to_linear(bgm_volume * master_volume)
		bgm_player.volume_db = linear_to_db(linear_volume)
	
	for player in sfx_players:
		var linear_volume = _volume_slider_to_linear(sfx_volume * master_volume)
		player.volume_db = linear_to_db(linear_volume)

# Convert linear slider value (0-1) to exponential curve for better perception
func _volume_slider_to_linear(slider_value: float) -> float:
	if slider_value <= 0.0:
		return 0.0
	return pow(slider_value, 3.0)

func get_save_data() -> Dictionary:
	return {
		"master_volume": master_volume,
		"bgm_volume": bgm_volume,
		"sfx_volume": sfx_volume,
		"current_bgm": current_bgm
	}

func load_save_data(data: Dictionary):
	if "master_volume" in data:
		master_volume = data.master_volume
	if "bgm_volume" in data:
		bgm_volume = data.bgm_volume
	if "sfx_volume" in data:
		sfx_volume = data.sfx_volume
	
	_apply_volume_settings()
	
	if "current_bgm" in data and data.current_bgm != "":
		play_bgm(data.current_bgm, 0.5)
