extends Node

# Save/Load Manager for persistent game data
const SAVE_FILE = "user://bugs_shooting_game_save.dat"
const SETTINGS_FILE = "user://game_settings.cfg"

# Game data structure
var game_data = {
	"high_score": 0,
	"total_bugs_killed": 0,
	"total_games_played": 0,
	"best_wave_reached": 1,
	"total_play_time": 0.0,
	"achievements": {},
	"player_stats": {
		"accuracy": 0.0,
		"shots_fired": 0,
		"shots_hit": 0
	},
	"unlocked_features": [],
	"first_time_playing": true
}

# Settings data
var settings_data = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.8,
	"graphics_quality": 1,  # 0=Low, 1=Medium, 2=High
	"auto_shoot": false,
	"camera_sensitivity": 1.0,
	"language": "en"
}

# Current session data
var session_start_time: float
var session_bugs_killed: int = 0
var session_shots_fired: int = 0
var session_shots_hit: int = 0
var game_timer: float = 0.0

func _ready():
	session_start_time = game_timer
	load_game_data()
	load_settings()

func _process(delta):
	game_timer += delta
	
	# Auto-save periodically
	var auto_save_timer = Timer.new()
	auto_save_timer.wait_time = 30.0  # Save every 30 seconds
	auto_save_timer.autostart = true
	auto_save_timer.timeout.connect(auto_save)
	add_child(auto_save_timer)

func save_game_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		print("Failed to open save file for writing")
		return false
	
	# Update session stats
	update_session_stats()
	
	# Convert to JSON and save
	var json_string = JSON.stringify(game_data)
	file.store_string(json_string)
	file.close()
	
	print("Game data saved successfully")
	return true

func load_game_data():
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		print("Save file not found, using default data")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Error parsing save file")
		return
	
	var loaded_data = json.data
	
	# Merge loaded data with defaults (in case new fields were added)
	for key in loaded_data:
		if game_data.has(key):
			game_data[key] = loaded_data[key]
	
	print("Game data loaded successfully")

func save_settings():
	var config = ConfigFile.new()
	
	# Save all settings
	for key in settings_data:
		config.set_value("settings", key, settings_data[key])
	
	var error = config.save(SETTINGS_FILE)
	if error == OK:
		print("Settings saved successfully")
		return true
	else:
		print("Failed to save settings: ", error)
		return false

func load_settings():
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE)
	
	if error != OK:
		print("Settings file not found, using defaults")
		save_settings()  # Create settings file with defaults
		return
	
	# Load all settings
	for key in settings_data:
		settings_data[key] = config.get_value("settings", key, settings_data[key])
	
	# Apply loaded settings
	apply_settings()
	print("Settings loaded successfully")

func apply_settings():
	# Apply audio settings
	if AudioManager:
		AudioManager.set_master_volume(settings_data.master_volume)
		AudioManager.set_music_volume(settings_data.music_volume)
		AudioManager.set_sfx_volume(settings_data.sfx_volume)
	
	# Apply graphics settings
	apply_graphics_settings()
	
	# Other settings can be applied here

func apply_graphics_settings():
	var quality = settings_data.graphics_quality
	
	match quality:
		0:  # Low
			# Basic quality settings - occlusion culling not available in Godot 4
			pass
		1:  # Medium
			pass
		2:  # High
			pass

# Game progress tracking
func update_high_score(new_score: int):
	if new_score > game_data.high_score:
		game_data.high_score = new_score
		check_score_achievements(new_score)
		save_game_data()

func add_bug_killed():
	game_data.total_bugs_killed += 1
	session_bugs_killed += 1
	
	# Check kill-based achievements
	check_kill_achievements()

func add_shot_fired():
	game_data.player_stats.shots_fired += 1
	session_shots_fired += 1

func add_shot_hit():
	game_data.player_stats.shots_hit += 1
	session_shots_hit += 1
	
	# Update accuracy
	update_accuracy()

func update_accuracy():
	var total_shots = game_data.player_stats.shots_fired
	if total_shots > 0:
		game_data.player_stats.accuracy = float(game_data.player_stats.shots_hit) / float(total_shots)

func update_wave_progress(wave: int):
	if wave > game_data.best_wave_reached:
		game_data.best_wave_reached = wave
		check_wave_achievements(wave)

func game_completed():
	game_data.total_games_played += 1
	update_session_stats()
	save_game_data()

func update_session_stats():
	var session_time = game_timer - session_start_time
	game_data.total_play_time += session_time
	
	# Reset session tracking
	session_start_time = game_timer

# Achievement system
func check_score_achievements(score: int):
	var achievements = game_data.achievements
	
	if score >= 1000 and not achievements.has("score_1000"):
		unlock_achievement("score_1000", "Score Master", "Reach 1000 points!")
	
	if score >= 5000 and not achievements.has("score_5000"):
		unlock_achievement("score_5000", "Score Legend", "Reach 5000 points!")

func check_kill_achievements():
	var total_kills = game_data.total_bugs_killed
	
	if total_kills >= 100 and not game_data.achievements.has("kills_100"):
		unlock_achievement("kills_100", "Bug Hunter", "Kill 100 bugs!")
	
	if total_kills >= 1000 and not game_data.achievements.has("kills_1000"):
		unlock_achievement("kills_1000", "Exterminator", "Kill 1000 bugs!")

func check_wave_achievements(wave: int):
	if wave >= 10 and not game_data.achievements.has("wave_10"):
		unlock_achievement("wave_10", "Survivor", "Reach wave 10!")
	
	if wave >= 25 and not game_data.achievements.has("wave_25"):
		unlock_achievement("wave_25", "Endurance Master", "Reach wave 25!")

func unlock_achievement(id: String, title: String, description: String):
	game_data.achievements[id] = {
		"title": title,
		"description": description,
		"unlocked_date": Time.get_date_string_from_system()
	}
	
	# Show achievement notification
	show_achievement_notification(title, description)
	
	save_game_data()

func show_achievement_notification(title: String, description: String):
	# This would show UI notification
	print("Achievement Unlocked: ", title, " - ", description)

# Settings getters/setters
func get_setting(key: String):
	return settings_data.get(key, null)

func set_setting(key: String, value):
	settings_data[key] = value
	save_settings()

# Game data getters
func get_high_score() -> int:
	return game_data.high_score

func get_total_bugs_killed() -> int:
	return game_data.total_bugs_killed

func get_total_games_played() -> int:
	return game_data.total_games_played

func get_best_wave() -> int:
	return game_data.best_wave_reached

func get_accuracy() -> float:
	return game_data.player_stats.accuracy

func get_total_play_time() -> float:
	return game_data.total_play_time

func is_first_time_playing() -> bool:
	return game_data.first_time_playing

func mark_tutorial_completed():
	game_data.first_time_playing = false
	save_game_data()

func get_achievements() -> Dictionary:
	return game_data.achievements

# Auto-save function
func auto_save():
	save_game_data()

# Reset progress (for testing or user request)
func reset_all_progress():
	game_data = {
		"high_score": 0,
		"total_bugs_killed": 0,
		"total_games_played": 0,
		"best_wave_reached": 1,
		"total_play_time": 0.0,
		"achievements": {},
		"player_stats": {
			"accuracy": 0.0,
			"shots_fired": 0,
			"shots_hit": 0
		},
		"unlocked_features": [],
		"first_time_playing": true
	}
	
	save_game_data()
	print("All progress reset")

# Export save data (for backup)
func export_save_data() -> String:
	return JSON.stringify(game_data)

# Import save data (for restore)
func import_save_data(json_string: String) -> bool:
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return false
	
	game_data = json.data
	save_game_data()
	return true
