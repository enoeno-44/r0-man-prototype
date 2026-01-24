# rhythm_minigame.gd
extends CanvasLayer

signal completed

# Nodes
@onready var start_panel = $StartPanel
@onready var countdown_label = $CountdownLabel
@onready var game_panel = $GamePanel
@onready var audio_player = $AudioStreamPlayer
@onready var score_label = $GamePanel/MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_label = $GamePanel/MarginContainer/VBoxContainer/ComboLabel
@onready var note_container = $NoteSpawner/NoteContainer
@onready var hit_zone = $HitZone
@onready var spacebar_hint = $SpacebarHint

# Game State
enum State { WAITING, COUNTDOWN, PLAYING, FINISHED }
var current_state = State.WAITING

# Score
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var perfect_hits: int = 0
var great_hits: int = 0
var good_hits: int = 0
var miss_count: int = 0

# Notes
var note_scene = preload("res://Minigames/Note.tscn")
var active_notes: Array = []

# Timing
var beat_times: Array = [2.5, 4.7, 6.9, 9.3, 11.4, 13.6, 15.9, 20.3, 22.5, 24.7, 29.1, 31.5, 33.6]
var song_duration: float = 41.0
var beat_pattern: Array = []
var game_time: float = 0.0

# Position
var spawn_y: float = 0.0
var hit_zone_y: float = 0.0
var note_speed: float = 200.0

const MIN_X: float = 400.0
const MAX_X: float = 730.0
const NOTE_SPACING: float = 100.0
const HIGHLIGHT_TIME: float = 0.2

# Hit Windows
const PERFECT_WINDOW: float = 0.7
const GREAT_WINDOW: float = 0.5
const GOOD_WINDOW: float = 0.3

func _ready():
	randomize()
	_calculate_positions()
	_generate_beat_pattern()
	hide()
	if get_parent() == get_tree().root:
		start_minigame()

func _calculate_positions():
	# คำนวณตำแหน่ง Spawn และ Hit Zone
	spawn_y = 0.0
	hit_zone_y = hit_zone.position.y

func _generate_beat_pattern():
	# สร้างจังหวะโน้ตพร้อมตำแหน่ง X แบบสุ่ม
	beat_pattern.clear()
	var used_positions: Array = []
	
	for beat_time in beat_times:
		var travel_distance = hit_zone_y - spawn_y
		var travel_time = travel_distance / note_speed
		var spawn_time = beat_time - travel_time
		var spawn_x = _get_random_position(used_positions)
		used_positions.append(spawn_x)
		
		if used_positions.size() > 3:
			used_positions.pop_front()
		
		beat_pattern.append({
			"time": beat_time,
			"spawn_time": spawn_time,
			"spawn_x": spawn_x,
			"spawned": false
		})

func _get_random_position(used_positions: Array) -> float:
	# สุ่มตำแหน่ง X โดยหลีกเลี่ยงตำแหน่งที่ใกล้กันเกินไป
	var max_attempts = 20
	var attempt = 0
	
	while attempt < max_attempts:
		var rand_x = randf_range(MIN_X, MAX_X)
		var is_valid = true
		
		for used_x in used_positions:
			if abs(rand_x - used_x) < NOTE_SPACING:
				is_valid = false
				break
		
		if is_valid:
			return rand_x
		
		attempt += 1
	
	return randf_range(MIN_X, MAX_X)

func start_minigame():
	show()
	current_state = State.WAITING
	
	start_panel.show()
	countdown_label.hide()
	game_panel.hide()
	hit_zone.hide()
	if spacebar_hint:
		spacebar_hint.hide()
	
	score = 0
	combo = 0
	max_combo = 0
	perfect_hits = 0
	great_hits = 0
	good_hits = 0
	miss_count = 0
	game_time = 0.0
	active_notes.clear()
	
	for beat in beat_pattern:
		beat.spawned = false
	
	for child in note_container.get_children():
		child.queue_free()

func _process(delta):
	match current_state:
		State.WAITING:
			_process_waiting()
		State.PLAYING:
			_process_playing(delta)

func _process_waiting():
	if Input.is_action_just_pressed("ui_accept"):
		_start_countdown()

func _start_countdown():
	# นับถอยหลัง 3, 2, 1 ก่อนเริ่มเกม
	current_state = State.COUNTDOWN
	start_panel.hide()
	countdown_label.show()
	game_panel.show()
	hit_zone.show()
	if spacebar_hint:
		spacebar_hint.show()
	_update_ui()
	
	for i in [3, 2, 1]:
		countdown_label.text = str(i)
		countdown_label.modulate = Color.RED if i == 1 else Color.YELLOW
		await get_tree().create_timer(1.0).timeout
	
	countdown_label.text = "START!"
	countdown_label.modulate = Color.GREEN
	await get_tree().create_timer(0.5).timeout
	countdown_label.hide()
	
	_start_game()

func _start_game():
	current_state = State.PLAYING
	game_time = 0.0
	audio_player.play()

func _process_playing(delta):
	# อัปเดตเกมขณะเล่น
	game_time += delta
	
	_spawn_notes()
	_update_notes(delta)
	_check_input()
	_remove_missed_notes()
	
	if not audio_player.playing and active_notes.is_empty():
		_complete_minigame()

func _spawn_notes():
	# สร้างโน้ตตามเวลาที่กำหนด
	for beat in beat_pattern:
		if beat.spawned:
			continue
		
		if game_time >= beat.spawn_time:
			_create_note(beat.time, beat.spawn_x)
			beat.spawned = true

func _create_note(hit_time: float, spawn_x: float):
	var note = note_scene.instantiate()
	note.position = Vector2(spawn_x, spawn_y)
	note.set_meta("hit_time", hit_time)
	note.set_meta("original_color", note.modulate)
	
	var key_label = note.get_node("KeyLabel")
	key_label.text = "SPACE"
	key_label.visible = false
	
	note_container.add_child(note)
	active_notes.append(note)

func _update_notes(delta):
	# เคลื่อนที่โน้ตลงมาและเปลี่ยนสีเมื่อใกล้ถึงเวลา
	for note in active_notes:
		if not is_instance_valid(note):
			continue
		
		note.position.y += note_speed * delta
		
		var hit_time = note.get_meta("hit_time")
		var time_until_hit = hit_time - game_time
		var key_label = note.get_node("KeyLabel")
		
		if time_until_hit <= HIGHLIGHT_TIME and time_until_hit > -GOOD_WINDOW:
			key_label.visible = true
			var intensity = 1.0 - (time_until_hit / HIGHLIGHT_TIME)
			intensity = clamp(intensity, 0.0, 1.0)
			note.modulate = Color.GREEN.lerp(Color.YELLOW, intensity)
		else:
			key_label.visible = false
			var original_color = note.get_meta("original_color", Color.WHITE)
			note.modulate = original_color

func _remove_missed_notes():
	# ลบโน้ตที่ผ่าน Hit Zone ไปแล้ว (Miss)
	var notes_to_remove = []
	
	for note in active_notes:
		if not is_instance_valid(note):
			notes_to_remove.append(note)
			continue
		
		var hit_time = note.get_meta("hit_time")
		
		if game_time > hit_time + GOOD_WINDOW:
			_on_miss()
			notes_to_remove.append(note)
			note.queue_free()
	
	for note in notes_to_remove:
		active_notes.erase(note)

func _check_input():
	if Input.is_action_just_pressed("ui_accept"):
		_on_spacebar_pressed()
		_flash_spacebar_hint()

func _on_spacebar_pressed():
	# ตรวจสอบการกดและคำนวณคะแนน
	if active_notes.is_empty():
		return
	
	var best_note = null
	var best_time_diff = 999999.0
	
	for note in active_notes:
		if not is_instance_valid(note):
			continue
		
		var hit_time = note.get_meta("hit_time")
		var time_diff = abs(game_time - hit_time)
		
		if time_diff < best_time_diff:
			best_time_diff = time_diff
			best_note = note
	
	if best_note == null:
		return
	
	var hit_time = best_note.get_meta("hit_time")
	var time_diff = game_time - hit_time
	
	var rating = ""
	var accuracy = 0.0
	
	if abs(time_diff) <= PERFECT_WINDOW:
		rating = "PERFECT!"
		accuracy = 1.0
		perfect_hits += 1
	elif abs(time_diff) <= GREAT_WINDOW:
		rating = "GREAT!"
		accuracy = 0.8
		great_hits += 1
	elif abs(time_diff) <= GOOD_WINDOW:
		rating = "GOOD"
		accuracy = 0.5
		good_hits += 1
	else:
		_on_miss()
		return
	
	_on_hit(accuracy, rating)
	active_notes.erase(best_note)
	best_note.queue_free()

func _on_hit(accuracy: float, rating: String):
	combo += 1
	max_combo = max(max_combo, combo)
	
	var base_score = 100
	var combo_bonus = combo * 20
	var accuracy_bonus = int(accuracy * 50)
	var total = base_score + combo_bonus + accuracy_bonus
	
	score += total
	_update_ui()

func _on_miss():
	miss_count += 1
	combo = 0
	_update_ui()

func _flash_spacebar_hint():
	# กระพริบปุ่ม Spacebar
	if not spacebar_hint:
		return
	
	spacebar_hint.modulate = Color.YELLOW
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(spacebar_hint):
		spacebar_hint.modulate = Color.WHITE

func _update_ui():
	score_label.text = "คะแนน: %d" % score
	combo_label.text = "Combo: x%d" % combo
	
	if combo >= 15:
		combo_label.modulate = Color.GOLD
	elif combo >= 10:
		combo_label.modulate = Color.ORANGE
	elif combo >= 5:
		combo_label.modulate = Color.YELLOW
	else:
		combo_label.modulate = Color.WHITE

func _complete_minigame():
	# จบเกมและแสดงผลสรุป
	if current_state == State.FINISHED:
		return
	
	current_state = State.FINISHED
	
	await get_tree().create_timer(3.0).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	completed.emit()
