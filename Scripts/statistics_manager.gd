# AutoLoad: StatisticsManager
extends Node

signal stats_updated

# QTE Statistics
var total_qte_attempts: int = 0  # จำนวน QTE ทั้งหมดที่ทำไป
var total_qte_success: int = 0   # จำนวน QTE ที่สำเร็จ
var total_qte_failed: int = 0    # จำนวน QTE ที่พลาด
var required_qte_count: int = 0  # จำนวน QTE ที่ต้องกดทั้งหมด (รวม required จากทุก object)

# Quest Statistics
var total_quests_completed: int = 0  # จำนวน Quest ที่ทำสำเร็จทั้งหมด

# Time Statistics
var total_playtime: float = 0.0  # เวลาเล่นทั้งหมด (วินาที)
var is_counting_time: bool = true  # สถานะการนับเวลา

func _ready():
	_connect_signals()
	print("[StatisticsManager] เริ่มต้นระบบสถิติ")

func _process(delta):
	# นับเวลาเล่นเมื่อเกมไม่ pause
	if is_counting_time and not get_tree().paused:
		total_playtime += delta
		stats_updated.emit()

func _connect_signals():
	# เชื่อมต่อกับ QTEManager
	if has_node("/root/QTEManager"):
		QTEManager.qte_success.connect(_on_qte_success)
		QTEManager.qte_failed.connect(_on_qte_failed)
		QTEManager.qte_started.connect(_on_qte_started)
	
	# เชื่อมต่อกับ QuestManager
	if has_node("/root/QuestManager"):
		QuestManager.quest_completed.connect(_on_quest_completed)

# ========== QTE Statistics Handlers ==========

func _on_qte_started(object_id: String):
	"""เมื่อเริ่ม QTE - บันทึก required count"""
	if QTEManager.qte_progress.has(object_id):
		var progress = QTEManager.qte_progress[object_id]
		required_qte_count += progress.required
		print("[Stats] QTE Started: %s (Required: %d)" % [object_id, progress.required])

func _on_qte_success(object_id: String, current_count: int, required_count: int):
	"""เมื่อกด QTE สำเร็จ"""
	total_qte_attempts += 1
	total_qte_success += 1
	stats_updated.emit()
	print("[Stats] QTE Success! Total: %d/%d (Success: %d, Failed: %d)" % 
		[total_qte_attempts, required_qte_count, total_qte_success, total_qte_failed])

func _on_qte_failed(object_id: String, current_count: int, required_count: int):
	"""เมื่อกด QTE ล้มเหลว"""
	total_qte_attempts += 1
	total_qte_failed += 1
	stats_updated.emit()
	print("[Stats] QTE Failed! Total: %d/%d (Success: %d, Failed: %d)" % 
		[total_qte_attempts, required_qte_count, total_qte_success, total_qte_failed])

# ========== Quest Statistics Handlers ==========

func _on_quest_completed(quest_id: String):
	"""เมื่อทำ Quest สำเร็จ"""
	total_quests_completed += 1
	stats_updated.emit()
	print("[Stats] Quest Completed! Total: %d" % total_quests_completed)

# ========== Time Control ==========

func pause_time_counting():
	"""หยุดนับเวลา (เมื่อ pause เกม)"""
	is_counting_time = false
	print("[Stats] หยุดนับเวลา")

func resume_time_counting():
	"""เริ่มนับเวลาต่อ"""
	is_counting_time = true
	print("[Stats] เริ่มนับเวลาต่อ")

# ========== Getters ==========

func get_qte_success_rate() -> float:
	"""คำนวณ Success Rate ของ QTE"""
	if total_qte_attempts == 0:
		return 0.0
	return (float(total_qte_success) / float(total_qte_attempts)) * 100.0

func get_playtime_formatted() -> String:
	"""แปลงเวลาเล่นเป็นรูปแบบ HH:MM:SS"""
	var hours = int(total_playtime / 3600)
	var minutes = int((int(total_playtime) % 3600) / 60)
	var seconds = int(total_playtime) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func get_all_stats() -> Dictionary:
	"""ดึงสถิติทั้งหมดในรูปแบบ Dictionary"""
	return {
		"qte": {
			"success": total_qte_success,
			"failed": total_qte_failed,
			"required_count": required_qte_count,
			"success_rate": get_qte_success_rate()
		},
		"quests": {
			"completed": total_quests_completed
		},
		"time": {
			"total_seconds": total_playtime,
			"formatted": get_playtime_formatted()
		}
	}

func get_stats_summary() -> String:
	"""สร้างข้อความสรุปสถิติ"""
	var summary = ""
	summary += "=== สถิติการเล่น ===\n"
	summary += "เวลาเล่นทั้งหมด: %s\n" % get_playtime_formatted()
	summary += "Quest ที่ทำสำเร็จ: %d\n" % total_quests_completed
	summary += "\n=== สถิติ QTE ===\n"
	summary += "QTE ที่ทำไปแล้ว: %d ครั้ง\n" % total_qte_attempts
	summary += "QTE สำเร็จ: %d ครั้ง\n" % total_qte_success
	summary += "QTE พลาด: %d ครั้ง\n" % total_qte_failed
	if total_qte_attempts > 0:
		summary += "Success Rate: %.1f%%\n" % get_qte_success_rate()
	return summary

# ========== Save/Load ==========

func get_save_data() -> Dictionary:
	"""ดึงข้อมูลสำหรับเซฟ"""
	return {
		"total_qte_attempts": total_qte_attempts,
		"total_qte_success": total_qte_success,
		"total_qte_failed": total_qte_failed,
		"required_qte_count": required_qte_count,
		"total_quests_completed": total_quests_completed,
		"total_playtime": total_playtime
	}

func load_save_data(data: Dictionary):
	"""โหลดข้อมูลจากเซฟ"""
	if "total_qte_attempts" in data:
		total_qte_attempts = data.total_qte_attempts
	if "total_qte_success" in data:
		total_qte_success = data.total_qte_success
	if "total_qte_failed" in data:
		total_qte_failed = data.total_qte_failed
	if "required_qte_count" in data:
		required_qte_count = data.required_qte_count
	if "total_quests_completed" in data:
		total_quests_completed = data.total_quests_completed
	if "total_playtime" in data:
		total_playtime = data.total_playtime
	
	print("[Stats] โหลดสถิติ - Playtime: %s, Quests: %d, QTE: %d/%d" % 
		[get_playtime_formatted(), total_quests_completed, total_qte_success, total_qte_failed])

# ========== Reset ==========

func reset_all_stats():
	"""รีเซ็ตสถิติทั้งหมด"""
	total_qte_attempts = 0
	total_qte_success = 0
	total_qte_failed = 0
	required_qte_count = 0
	total_quests_completed = 0
	total_playtime = 0.0
	is_counting_time = true
	stats_updated.emit()
	print("[Stats] รีเซ็ตสถิติทั้งหมดแล้ว")
