extends Control

# Game Over UI Manager
@onready var game_over_label = $Panel/VBoxContainer/GameOverLabel
@onready var final_score_label = $Panel/VBoxContainer/FinalScoreLabel
@onready var high_score_label = $Panel/VBoxContainer/HighScoreLabel
@onready var stats_container = $Panel/VBoxContainer/StatsContainer
@onready var wave_label = $Panel/VBoxContainer/StatsContainer/WaveLabel
@onready var accuracy_label = $Panel/VBoxContainer/StatsContainer/AccuracyLabel
@onready var bugs_killed_label = $Panel/VBoxContainer/StatsContainer/BugsKilledLabel

# Buttons
@onready var restart_button = $Panel/VBoxContainer/ButtonContainer/RestartButton
@onready var main_menu_button = $Panel/VBoxContainer/ButtonContainer/MainMenuButton
@onready var share_button = $Panel/VBoxContainer/ButtonContainer/ShareButton

# Effects
@onready var confetti_particles = $ConfettiParticles
@onready var background_overlay = $BackgroundOverlay

# Data
var final_score: int = 0
var wave_reached: int = 1
var bugs_killed_this_game: int = 0
var accuracy_percentage: float = 0.0
var is_new_high_score: bool = false

func _ready():
    # Initially hidden
    visible = false
    
    # Connect buttons
    connect_buttons()
    
    # Connect to game manager
    if GameManager:
        GameManager.game_over.connect(show_game_over_screen)

func connect_buttons():
    if restart_button:
        restart_button.pressed.connect(_on_restart_pressed)
    
    if main_menu_button:
        main_menu_button.pressed.connect(_on_main_menu_pressed)
    
    if share_button:
        share_button.pressed.connect(_on_share_pressed)
        
        # Hide share button on desktop
        if OS.get_name() != "Android" and OS.get_name() != "iOS":
            share_button.visible = false

func show_game_over_screen():
    # Get game data
    collect_game_data()
    
    # Update UI elements
    update_display()
    
    # Show with animation
    visible = true
    animate_appearance()
    
    # Play sound
    AudioManager.play_game_over_sound()
    
    # Show confetti if new high score
    if is_new_high_score:
        show_celebration_effects()

func collect_game_data():
    if GameManager:
        final_score = GameManager.get_score()
        wave_reached = GameManager.get_current_wave()
        
        # Check if new high score
        var old_high_score = SaveLoadManager.get_high_score()
        is_new_high_score = final_score > old_high_score
        
        # Update save data
        SaveLoadManager.update_high_score(final_score)
        SaveLoadManager.update_wave_progress(wave_reached)
        SaveLoadManager.game_completed()
    
    # Get session stats
    bugs_killed_this_game = SaveLoadManager.session_bugs_killed
    
    # Calculate accuracy
    var shots_fired = SaveLoadManager.session_shots_fired
    var shots_hit = SaveLoadManager.session_shots_hit
    
    if shots_fired > 0:
        accuracy_percentage = (float(shots_hit) / float(shots_fired)) * 100.0
    else:
        accuracy_percentage = 0.0

func update_display():
    # Game Over title
    if game_over_label:
        if is_new_high_score:
            game_over_label.text = "NEW HIGH SCORE!"
            game_over_label.modulate = Color.GOLD
        else:
            game_over_label.text = "GAME OVER"
            game_over_label.modulate = Color.WHITE
    
    # Final score
    if final_score_label:
        final_score_label.text = "Score: " + str(final_score)
    
    # High score
    if high_score_label:
        var high_score = SaveLoadManager.get_high_score()
        high_score_label.text = "High Score: " + str(high_score)
    
    # Wave reached
    if wave_label:
        wave_label.text = "Wave Reached: " + str(wave_reached)
    
    # Accuracy
    if accuracy_label:
        accuracy_label.text = "Accuracy: " + str(accuracy_percentage).pad_decimals(1) + "%"
    
    # Bugs killed this game
    if bugs_killed_label:
        bugs_killed_label.text = "Bugs Killed: " + str(bugs_killed_this_game)

func animate_appearance():
    # Background fade in
    if background_overlay:
        background_overlay.modulate.a = 0.0
        var bg_tween = create_tween()
        bg_tween.tween_property(background_overlay, "modulate:a", 0.8, 0.5)
    
    # Panel slide in from top
    var panel = $Panel
    if panel:
        panel.position.y = -panel.size.y
        panel.modulate.a = 0.0
        
        var panel_tween = create_tween()
        panel_tween.set_parallel(true)
        
        panel_tween.tween_property(panel, "position:y", 0, 0.5)
        panel_tween.tween_property(panel, "modulate:a", 1.0, 0.5)
    
    # Animate labels appearing one by one
    animate_labels_sequence()

func animate_labels_sequence():
    var labels = [final_score_label, high_score_label, wave_label, accuracy_label, bugs_killed_label]
    
    for i in range(labels.size()):
        if labels[i]:
            labels[i].modulate.a = 0.0
            labels[i].scale = Vector2(0.5, 0.5)
            
            # Delay each label
            await get_tree().create_timer(0.2 * i).timeout
            
            var tween = create_tween()
            tween.set_parallel(true)
            tween.tween_property(labels[i], "modulate:a", 1.0, 0.3)
            tween.tween_property(labels[i], "scale", Vector2(1.0, 1.0), 0.3)

func show_celebration_effects():
    # Confetti particles
    if confetti_particles:
        confetti_particles.emitting = true
    
    # Screen flash
    var flash = ColorRect.new()
    flash.color = Color.GOLD * 0.3
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(flash)
    
    var flash_tween = create_tween()
    flash_tween.tween_property(flash, "modulate:a", 0.0, 1.0)
    flash_tween.tween_callback(func(): flash.queue_free())
    
    # Play celebration sound
    AudioManager.play_celebration_sound()

func _on_restart_pressed():
    AudioManager.play_ui_click_sound()
    
    # Fade out
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    
    await tween.finished
    
    # Restart game
    GameManager.restart_game()
    visible = false
    modulate.a = 1.0

func _on_main_menu_pressed():
    AudioManager.play_ui_click_sound()
    
    # Fade out
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    
    await tween.finished
    
    # Go to main menu
    SceneTransitionManager.change_scene("res://scenes/MainMenu.tscn")

func _on_share_pressed():
    # Mobile sharing functionality
    if OS.get_name() == "Android":
        share_score_android()
    elif OS.get_name() == "iOS":
        share_score_ios()

func share_score_android():
    # Android intent for sharing
    var share_text = "I just scored %d points in Bugs Shooting Game! Can you beat my score?" % final_score
    
    if OS.has_method("share"):
        OS.share(share_text)
    else:
        # Fallback - copy to clipboard
        DisplayServer.clipboard_set(share_text)
        show_message("Score copied to clipboard!")

func share_score_ios():
    # iOS sharing (if available)
    var share_text = "I just scored %d points in Bugs Shooting Game! Can you beat my score?" % final_score
    
    if OS.has_method("share"):
        OS.share(share_text)
    else:
        # Fallback - copy to clipboard
        DisplayServer.clipboard_set(share_text)
        show_message("Score copied to clipboard!")

func show_message(text: String):
    # Show temporary message
    var message_label = Label.new()
    message_label.text = text
    message_label.add_theme_font_size_override("font_size", 24)
    message_label.modulate = Color.YELLOW
    message_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    
    add_child(message_label)
    
    # Animate message
    var tween = create_tween()
    tween.tween_property(message_label, "position:y", message_label.position.y - 50, 1.0)
    tween.parallel().tween_property(message_label, "modulate:a", 0.0, 1.0)
    tween.tween_callback(func(): message_label.queue_free())

func _input(event):
    # Handle back button (Android)
    if event.is_action_pressed("ui_cancel") and visible:
        _on_main_menu_pressed()