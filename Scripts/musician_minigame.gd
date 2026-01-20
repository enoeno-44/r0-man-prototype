# rhythm_minigame.gd
extends CanvasLayer

signal completed

# === NODES ===
@onready var start_panel = $StartPanel
@onready var countdown_label = $CountdownLabel
@onready var game_panel = $GamePanel
@onready var audio_player = $AudioStreamPlayer
@onready var score_label = $GamePanel/MarginContainer/VBoxContainer/ScoreLabel
@onready var combo_label = $GamePanel/MarginContainer/VBoxContainer/ComboLabel
@onready var note_container = $NoteSpawner/NoteContainer
@onready var hit_zone = $HitZone
@onready var spacebar_hint = $SpacebarHint

# === GAME STATE ===
enum State { WAITING, COUNTDOWN, PLAYING, FINISHED }
var current_state = State.WAITING

var score: int = 0
var combo: int = 0
var max_combo: int = 0
var perfect_hits: int = 0
var great_hits: int = 0
var good_hits: int = 0
var miss_count: int = 0

# === NOTE SETTINGS ===
var note_scene = preload("res://Minigames/Note.tscn")
var active_notes: Array = []

# === TIMING SETTINGS ===
#var beat_times: Array = [
	#2.3, 4.5, 6.7, 9.1, 11.2, 13.4 ,15.7, 20.1, 22.3, 24.5, 28.9, 31.3, 33.4
#]
var beat_times: Array = [
	2.5, 4.7, 6.9, 9.3, 11.4, 13.6 ,15.9, 20.3, 22.5, 24.7, 29.1, 31.5, 33.6
]
#var beat_times: Array = [
	#2.4, 4.6, 6.8, 9.2, 11.3, 13.5 ,15.8, 20.2, 22.4, 24.6, 29.0, 31.4, 33.5
#]

var song_duration: float = 41.0
var beat_pattern: Array = []
var game_time: float = 0.0

# การคำนวดความเร็วและระยะทาง
var spawn_y: float = 0.0
var hit_zone_y: float = 0.0
var note_speed: float = 200.0  # ความเร็วคงที่ (pixels ต่อวินาที)

# ตำแหน่ง X ที่สุ่มได้
const MIN_X: float = 400.0
const MAX_X: float = 730.0  # 1024 - 200 = 824
const NOTE_SPACING: float = 100.0  # ระยะห่างขั้นต่ำระหว่าง Note

# ช่วงเวลาที่ Note จะเปลี่ยนสี (ก่อนถึง hit time)
const HIGHLIGHT_TIME: float = 0.2  # เปลี่ยนสีเมื่อเหลือ 0.3 วินาที

# ช่วงเวลาที่ถือว่ากดถูก (วินาที)
const PERFECT_WINDOW: float = 0.7
const GREAT_WINDOW: float = 0.5
const GOOD_WINDOW: float = 0.3

func _ready():
	randomize()  # เริ่มต้น random seed
	_calculate_positions()
	_generate_beat_pattern()
	hide()
	if get_parent() == get_tree().root:
		start_minigame()

func _calculate_positions():
	"""คำนวดตำแหน่ง Spawn และ Hit Zone"""
	spawn_y = 0.0
	hit_zone_y = hit_zone.position.y
	
	print("========================================")
	print("คำนวด Positions")
	print("========================================")
	print("  Spawn Y: %.1f" % spawn_y)
	print("  Hit Zone Y: %.1f" % hit_zone_y)
	print("  ความเร็ว Note: %.1f pixels/วินาที" % note_speed)
	print("  ตำแหน่ง X: %.1f - %.1f" % [MIN_X, MAX_X])
	print("========================================")

func _generate_beat_pattern():
	"""สร้างจังหวะ"""
	beat_pattern.clear()
	var used_positions: Array = []
	
	for beat_time in beat_times:
		# คำนวดเวลาที่ต้อง spawn เพื่อให้ถึง hit zone พอดีเวลา
		var travel_distance = hit_zone_y - spawn_y
		var travel_time = travel_distance / note_speed
		var spawn_time = beat_time - travel_time
		
		# สุ่มตำแหน่ง X โดยหลีกเลี่ยงตำแหน่งที่ใกล้กันเกินไป
		var spawn_x = _get_random_position(used_positions)
		used_positions.append(spawn_x)
		
		# เก็บแค่ตำแหน่ง 3 อันล่าสุด เพื่อไม่ให้ซ้ำกันมากเกินไป
		if used_positions.size() > 3:
			used_positions.pop_front()
		
		beat_pattern.append({
			"time": beat_time,
			"spawn_time": spawn_time,
			"spawn_x": spawn_x,
			"spawned": false
		})
	
	print("สร้างจังหวะเสร็จแล้ว!")
	print("  - จำนวนโน้ต: %d โน้ต" % beat_pattern.size())
	print("========================================")

func _get_random_position(used_positions: Array) -> float:
	"""สุ่มตำแหน่ง X โดยหลีกเลี่ยงตำแหน่งที่ใกล้กันเกินไป"""
	var max_attempts = 20
	var attempt = 0
	
	while attempt < max_attempts:
		var rand_x = randf_range(MIN_X, MAX_X)
		var is_valid = true
		
		# ตรวจสอบว่าไม่ใกล้กับตำแหน่งที่เคยใช้มากเกินไป
		for used_x in used_positions:
			if abs(rand_x - used_x) < NOTE_SPACING:
				is_valid = false
				break
		
		if is_valid:
			return rand_x
		
		attempt += 1
	
	# ถ้าหาไม่เจอภายใน 20 ครั้ง ให้ใช้ตำแหน่งสุ่มทั่วไป
	return randf_range(MIN_X, MAX_X)

func start_minigame():
	"""แสดงหน้าจอเริ่มต้น"""
	print("[RhythmMinigame] เริ่มต้น Minigame")
	show()
	current_state = State.WAITING
	
	start_panel.show()
	countdown_label.hide()
	game_panel.hide()
	hit_zone.hide()
	if spacebar_hint:
		spacebar_hint.hide()
	
	# รีเซ็ตค่า
	score = 0
	combo = 0
	max_combo = 0
	perfect_hits = 0
	great_hits = 0
	good_hits = 0
	miss_count = 0
	game_time = 0.0
	active_notes.clear()
	
	# รีเซ็ต spawned flags
	for beat in beat_pattern:
		beat.spawned = false
	
	# ลบโน้ตเก่า
	for child in note_container.get_children():
		child.queue_free()

func _process(delta):
	match current_state:
		State.WAITING:
			_process_waiting()
		State.PLAYING:
			_process_playing(delta)

func _process_waiting():
	"""รอผู้เล่นกด Space"""
	if Input.is_action_just_pressed("ui_accept"):
		_start_countdown()

func _start_countdown():
	"""เริ่มนับถอยหลัง 3 วินาที"""
	print("[RhythmMinigame] เริ่มนับถอยหลัง")
	current_state = State.COUNTDOWN
	start_panel.hide()
	countdown_label.show()
	
	game_panel.show()
	hit_zone.show()
	if spacebar_hint:
		spacebar_hint.show()
	_update_ui()
	
	# นับถอยหลัง 3, 2, 1
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
	"""เริ่มเล่นเพลงและเกม"""
	print("[RhythmMinigame] เริ่มเกม!")
	current_state = State.PLAYING
	game_time = 0.0
	audio_player.play()

func _process_playing(delta):
	"""อัปเดตเกมขณะเล่น"""
	game_time += delta
	
	_spawn_notes()
	_update_notes(delta)
	_check_input()
	_remove_missed_notes()
	
	if not audio_player.playing and active_notes.is_empty():
		_complete_minigame()

func _spawn_notes():
	"""สร้างโน้ตตามเวลาที่กำหนด"""
	for beat in beat_pattern:
		if beat.spawned:
			continue
		
		if game_time >= beat.spawn_time:
			_create_note(beat.time, beat.spawn_x)
			beat.spawned = true

func _create_note(hit_time: float, spawn_x: float):
	"""สร้างโน้ตใหม่"""
	var note = note_scene.instantiate()
	note.position = Vector2(spawn_x, spawn_y)
	note.set_meta("hit_time", hit_time)
	note.set_meta("original_color", note.modulate)
	
	# ซ่อน KeyLabel ไว้ก่อน
	var key_label = note.get_node("KeyLabel")
	key_label.text = "SPACE"
	key_label.visible = false
	
	note_container.add_child(note)
	active_notes.append(note)
	
	print("[Spawn] โน้ต | ตำแหน่ง X: %.1f | ต้องกดที่: %.2fs" % [spawn_x, hit_time])

func _update_notes(delta):
	"""เคลื่อนที่โน้ตลงมาและเปลี่ยนสีเมื่อใกล้ถึงเวลา"""
	for note in active_notes:
		if not is_instance_valid(note):
			continue
		
		# เคลื่อนที่ลงมา
		note.position.y += note_speed * delta
		
		# เช็คว่าใกล้ถึงเวลากดหรือยัง
		var hit_time = note.get_meta("hit_time")
		var time_until_hit = hit_time - game_time
		
		# เปลี่ยนสีและแสดง KeyLabel เมื่อใกล้ถึงเวลากด
		var key_label = note.get_node("KeyLabel")
		
		if time_until_hit <= HIGHLIGHT_TIME and time_until_hit > -GOOD_WINDOW:
			# แสดง KeyLabel
			key_label.visible = true
			
			# คำนวดความเข้มของสี (เริ่มจาง ๆ แล้วเข้มขึ้น)
			var intensity = 1.0 - (time_until_hit / HIGHLIGHT_TIME)
			intensity = clamp(intensity, 0.0, 1.0)
			
			# เปลี่ยนเป็นสีเขียวเรืองแสง
			note.modulate = Color.GREEN.lerp(Color.YELLOW, intensity)
		else:
			# ซ่อน KeyLabel
			key_label.visible = false
			
			# สีปกติ (ขาว)
			var original_color = note.get_meta("original_color", Color.WHITE)
			note.modulate = original_color

func _remove_missed_notes():
	"""ลบโน้ตที่ผ่าน Hit Zone ไปแล้ว (Miss)"""
	var notes_to_remove = []
	
	for note in active_notes:
		if not is_instance_valid(note):
			notes_to_remove.append(note)
			continue
		
		var hit_time = note.get_meta("hit_time")
		
		if game_time > hit_time + GOOD_WINDOW:
			print("[Miss] โน้ต | เวลา: %.2fs | พลาด: +%.3fs" % 
				[game_time, game_time - hit_time])
			_on_miss()
			notes_to_remove.append(note)
			note.queue_free()
	
	for note in notes_to_remove:
		active_notes.erase(note)

func _check_input():
	"""เช็คการกด Spacebar"""
	if Input.is_action_just_pressed("ui_accept"):
		_on_spacebar_pressed()
		_flash_spacebar_hint()

func _on_spacebar_pressed():
	"""เมื่อกด Spacebar"""
	if active_notes.is_empty():
		return
	
	# หาโน้ตที่ใกล้เวลาที่สุด
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
	
	# กำหนด rating ตามความแม่นยำ
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
		# กดช้า/เร็วเกินไป
		print("[Too Early/Late] ส่วนต่าง: %.3fs" % time_diff)
		_on_miss()
		return
	
	print("[%s] เวลา: %.2fs | ส่วนต่าง: %+.3fs" % 
		[rating, game_time, time_diff])
	
	_on_hit(accuracy, rating)
	active_notes.erase(best_note)
	best_note.queue_free()

func _on_hit(accuracy: float, rating: String):
	"""เมื่อกดถูก"""
	combo += 1
	max_combo = max(max_combo, combo)
	
	var base_score = 100
	var combo_bonus = combo * 20
	var accuracy_bonus = int(accuracy * 50)
	var total = base_score + combo_bonus + accuracy_bonus
	
	score += total
	
	print("  → +%d คะแนน | Combo x%d" % [total, combo])
	_update_ui()

func _on_miss():
	"""เมื่อพลาด"""
	miss_count += 1
	combo = 0
	_update_ui()

func _flash_spacebar_hint():
	"""กระพริบปุ่ม Spacebar"""
	if not spacebar_hint:
		return
	
	spacebar_hint.modulate = Color.YELLOW
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(spacebar_hint):
		spacebar_hint.modulate = Color.WHITE

func _update_ui():
	"""อัปเดต UI"""
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
	"""จบเกม"""
	if current_state == State.FINISHED:
		return
	
	current_state = State.FINISHED
	
	var total_notes = beat_pattern.size()
	var hit_notes = perfect_hits + great_hits + good_hits
	var accuracy_percent = (float(hit_notes) / total_notes) * 100.0
	
	print("")
	print("========================================")
	print("        เกมจบแล้ว!")
	print("========================================")
	print("  คะแนนรวม: %d" % score)
	print("  Max Combo: x%d" % max_combo)
	print("  Perfect: %d" % perfect_hits)
	print("  Great: %d" % great_hits)
	print("  Good: %d" % good_hits)
	print("  Miss: %d" % miss_count)
	print("  ความแม่นยำ: %.1f%%" % accuracy_percent)
	print("========================================")
	
	var result_text = "เกมจบ!\n\n"
	result_text += "คะแนน: %d\n" % score
	result_text += "Max Combo: x%d\n\n" % max_combo
	result_text += "Perfect: %d | Great: %d\n" % [perfect_hits, great_hits]
	result_text += "Good: %d | Miss: %d\n" % [good_hits, miss_count]
	result_text += "ความแม่นยำ: %.1f%%" % accuracy_percent
	
	countdown_label.text = result_text
	countdown_label.modulate = Color.GREEN
	countdown_label.show()
	
	await get_tree().create_timer(5.0).timeout
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(true)
		if player.has_method("set_can_move"):
			player.set_can_move(true)
	
	hide()
	completed.emit()
