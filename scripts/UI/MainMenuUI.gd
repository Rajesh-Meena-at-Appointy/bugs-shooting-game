extends Control

# Main Menu UI Manager
@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var achievements_button = $VBoxContainer/AchievementsButton
@onready var quit_button = $VBoxContainer/QuitButton

@onready var high_score_label = $HighScoreContainer/HighScoreLabel
@onready var stats_label = $StatsContainer/StatsLabel

# Background elements
@onready var background_bugs = $BackgroundBugs
@onready var title_label = $TitleContainer/TitleLabel

# Settings panel
@onready var settings_panel = $SettingsPanel
@onready var achievements_panel = $AchievementsPanel

func _ready():
	# Connect buttons
	connect_buttons()
	
	# Update display
	update_stats_display()
	
	# Animate title
	animate_title()
	
	# Start background animation
	start_background_animation()
	
	# Check if first time playing
	if SaveLoadManager.is_first_time_playing():
		show_welcome_message()

func connect_buttons():
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	
	if achievements_button:
		achievements_button.pressed.connect(_on_achievements_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	# Hide quit button on mobile
	if OS.get_name() == "Android" or OS.get_name() == "iOS":
		if quit_button:
			quit_button.visible = false

func _on_play_pressed():
	AudioManager.play_ui_click_sound()
	
	# Fade out menu
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	await tween.finished
	
	# Start game
	SceneTransitionManager.change_scene("res://scenes/Main.tscn")

func _on_settings_pressed():
	AudioManager.play_ui_click_sound()
	show_settings_panel()

func _on_achievements_pressed():
	AudioManager.play_ui_click_sound()
	show_achievements_panel()

func _on_quit_pressed():
	AudioManager.play_ui_click_sound()
	
	# Confirmation dialog
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Are you sure you want to quit?"
	add_child(confirmation)
	confirmation.confirmed.connect(quit_game)
	confirmation.popup_centered()

func quit_game():
	get_tree().quit()

func update_stats_display():
	# Update high score
	if high_score_label:
		var high_score = SaveLoadManager.get_high_score()
		high_score_label.text = "High Score: " + str(high_score)
	
	# Update stats
	if stats_label:
		var total_bugs = SaveLoadManager.get_total_bugs_killed()
		var total_games = SaveLoadManager.get_total_games_played()
		var best_wave = SaveLoadManager.get_best_wave()
		
		stats_label.text = "Bugs Killed: %d | Games Played: %d | Best Wave: %d" % [
			total_bugs, total_games, best_wave
		]

func animate_title():
	if not title_label:
		return
	
	# Bouncing title animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "scale", Vector2(1.1, 1.1), 1.0)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0)

func start_background_animation():
	if not background_bugs:
		return
	
	# Animate background bugs floating around
	for child in background_bugs.get_children():
		if child is Control:
			animate_background_bug(child)

func animate_background_bug(bug: Control):
	var tween = create_tween()
	tween.set_loops()
	
	# Random floating movement
	var start_pos = bug.position
	var end_pos = start_pos + Vector2(
		randf_range(-50, 50),
		randf_range(-30, 30)
	)
	
	var duration = randf_range(3.0, 6.0)
	
	tween.tween_property(bug, "position", end_pos, duration)
	tween.tween_property(bug, "position", start_pos, duration)
	
	# Also rotate
	tween.parallel().tween_property(bug, "rotation", TAU, duration * 2)

func show_settings_panel():
	if settings_panel:
		settings_panel.visible = true
		settings_panel.modulate.a = 0.0
		
		var tween = create_tween()
		tween.tween_property(settings_panel, "modulate:a", 1.0, 0.3)

func hide_settings_panel():
	if settings_panel:
		var tween = create_tween()
		tween.tween_property(settings_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): settings_panel.visible = false)

func show_achievements_panel():
	if achievements_panel:
		update_achievements_display()
		achievements_panel.visible = true
		achievements_panel.modulate.a = 0.0
		
		var tween = create_tween()
		tween.tween_property(achievements_panel, "modulate:a", 1.0, 0.3)

func hide_achievements_panel():
	if achievements_panel:
		var tween = create_tween()
		tween.tween_property(achievements_panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func(): achievements_panel.visible = false)

func update_achievements_display():
	var achievements = SaveLoadManager.get_achievements()
	var achievements_list = achievements_panel.get_node("ScrollContainer/AchievementsList")
	
	# Clear existing achievements
	for child in achievements_list.get_children():
		child.queue_free()
	
	# Add each achievement
	for achievement_id in achievements:
		var achievement_data = achievements[achievement_id]
		create_achievement_item(achievements_list, achievement_data)

func create_achievement_item(parent: Node, data: Dictionary):
	# TODO: Create AchievementItem.tscn in res://ui/
	# var item = preload("res://ui/AchievementItem.tscn").instantiate()
	# parent.add_child(item)
	# item.get_node("Title").text = data.title
	# item.get_node("Description").text = data.description
	
	# Temporary simple label for achievements
	var item = Label.new()
	item.text = data.title + ": " + data.description
	if data.has("unlocked_date"):
		item.text += " (Unlocked: " + data.unlocked_date + ")"
	parent.add_child(item)

func show_welcome_message():
	# First time player welcome
	var welcome_dialog = AcceptDialog.new()
	welcome_dialog.title = "Welcome!"
	welcome_dialog.dialog_text = "Welcome to Bugs Shooting Game!\n\nShoot the colorful bugs before they reach the food.\nUse WASD to move and mouse to look around.\nOn mobile, use the virtual controls.\n\nHave fun!"
	
	add_child(welcome_dialog)
	welcome_dialog.popup_centered()
	welcome_dialog.confirmed.connect(func(): SaveLoadManager.mark_tutorial_completed())

func _input(event):
	# Handle back button on Android
	if event.is_action_pressed("ui_cancel"):
		if settings_panel and settings_panel.visible:
			hide_settings_panel()
		elif achievements_panel and achievements_panel.visible:
			hide_achievements_panel()
		else:
			# Exit app on Android
			if OS.get_name() == "Android":
				get_tree().quit()
