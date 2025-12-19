extends Control

# UI References
@onready var score_label = $HUD/ScoreLabel
@onready var lives_label = $HUD/LivesLabel
@onready var wave_label = $HUD/WaveLabel
@onready var game_over_panel = $HUD/GameOverPanel
@onready var game_over_label = $HUD/GameOverPanel/GameOverLabel
@onready var final_score_label = $HUD/GameOverPanel/FinalScoreLabel
@onready var restart_button = $HUD/GameOverPanel/RestartButton
@onready var pause_panel = $HUD/PausePanel
@onready var resume_button = $HUD/PausePanel/ResumeButton
@onready var main_menu_button = $HUD/PausePanel/MainMenuButton

# Animation
var score_tween: Tween

func _ready():
    # Add to UI group
    add_to_group("ui")
    
    # Connect to game manager signals
    if GameManager:
        GameManager.score_changed.connect(_on_score_changed)
        GameManager.lives_changed.connect(_on_lives_changed)
        GameManager.game_over.connect(_on_game_over)
        GameManager.game_started.connect(_on_game_started)
        GameManager.wave_completed.connect(_on_wave_completed)
    
    # Set up buttons
    setup_buttons()
    
    # Initial UI state
    hide_game_over_panel()
    hide_pause_panel()

func setup_buttons():
    if restart_button:
        restart_button.pressed.connect(_on_restart_pressed)
    
    if resume_button:
        resume_button.pressed.connect(_on_resume_pressed)
    
    if main_menu_button:
        main_menu_button.pressed.connect(_on_main_menu_pressed)

# Game Manager signal callbacks
func _on_score_changed(new_score: int):
    if score_label:
        score_label.text = "Score: " + str(new_score)
        
        # Animate score change
        animate_score_change()

func _on_lives_changed(new_lives: int):
    if lives_label:
        lives_label.text = "Lives: " + str(new_lives)
        
        # Color feedback for low lives
        if new_lives <= 1:
            lives_label.modulate = Color.RED
        elif new_lives <= 2:
            lives_label.modulate = Color.YELLOW
        else:
            lives_label.modulate = Color.WHITE

func _on_wave_completed(wave_number: int):
    if wave_label:
        wave_label.text = "Wave: " + str(wave_number + 1)
        
        # Show wave completion message briefly
        show_wave_message("Wave " + str(wave_number) + " Complete!")

func _on_game_over():
    show_game_over_panel()

func _on_game_started():
    hide_game_over_panel()
    
    # Reset UI
    if score_label:
        score_label.text = "Score: 0"
    if lives_label:
        lives_label.text = "Lives: " + str(GameManager.get_lives())
        lives_label.modulate = Color.WHITE
    if wave_label:
        wave_label.text = "Wave: 1"

# UI Panel Management
func show_game_over_panel():
    if not game_over_panel:
        return
    
    game_over_panel.visible = true
    
    # Update final score
    if final_score_label:
        final_score_label.text = "Final Score: " + str(GameManager.get_score())
        
        if GameManager.get_score() == GameManager.get_high_score():
            final_score_label.text += "\nNEW HIGH SCORE!"
    
    # Animate panel appearance
    game_over_panel.modulate.a = 0.0
    var tween = create_tween()
    tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.5)

func hide_game_over_panel():
    if game_over_panel:
        game_over_panel.visible = false

func show_pause_panel():
    if pause_panel:
        pause_panel.visible = true

func hide_pause_panel():
    if pause_panel:
        pause_panel.visible = false

# Animations
func animate_score_change():
    if not score_label:
        return
    
    # Stop previous tween
    if score_tween:
        score_tween.kill()
    
    score_tween = create_tween()
    
    # Scale pulse effect
    score_tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.1)
    score_tween.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)

func show_wave_message(message: String):
    # Create temporary label for wave message
    var wave_message = Label.new()
    wave_message.text = message
    wave_message.add_theme_font_size_override("font_size", 32)
    wave_message.modulate = Color.YELLOW
    wave_message.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    
    add_child(wave_message)
    
    # Animate message
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Fade in, scale up, then fade out
    wave_message.modulate.a = 0.0
    wave_message.scale = Vector2.ZERO
    
    tween.tween_property(wave_message, "modulate:a", 1.0, 0.3)
    tween.tween_property(wave_message, "scale", Vector2(1.0, 1.0), 0.3)
    
    # Hold for a moment
    await tween.finished
    await get_tree().create_timer(1.0).timeout
    
    # Fade out
    var fade_tween = create_tween()
    fade_tween.tween_property(wave_message, "modulate:a", 0.0, 0.3)
    await fade_tween.finished
    
    wave_message.queue_free()

# Button callbacks
func _on_restart_pressed():
    if GameManager:
        GameManager.restart_game()

func _on_resume_pressed():
    if GameManager:
        GameManager.resume_game()
    hide_pause_panel()

func _on_main_menu_pressed():
    # Implement main menu transition
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# Public methods for external control
func update_high_score_display():
    # Called when high score changes
    if GameManager:
        var high_score_text = "High Score: " + str(GameManager.get_high_score())
        # Add high score label if needed