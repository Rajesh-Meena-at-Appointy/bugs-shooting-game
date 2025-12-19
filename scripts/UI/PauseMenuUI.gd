extends Control

# PauseMenuUI - Dedicated pause menu controller
class_name PauseMenuUI

# UI Elements
@onready var pause_panel = $PausePanel
@onready var resume_button = $PausePanel/VBoxContainer/ResumeButton
@onready var settings_button = $PausePanel/VBoxContainer/SettingsButton
@onready var main_menu_button = $PausePanel/VBoxContainer/MainMenuButton
@onready var quit_button = $PausePanel/VBoxContainer/QuitButton

# Overlay
@onready var background_overlay = $BackgroundOverlay

# State
var is_paused: bool = false

func _ready():
    # Initially hidden
    visible = false
    
    # Connect buttons
    connect_buttons()
    
    # Connect to game manager
    if GameManager:
        GameManager.game_over.connect(hide_pause_menu)

func connect_buttons():
    if resume_button:
        resume_button.pressed.connect(_on_resume_pressed)
    
    if settings_button:
        settings_button.pressed.connect(_on_settings_pressed)
    
    if main_menu_button:
        main_menu_button.pressed.connect(_on_main_menu_pressed)
    
    if quit_button:
        quit_button.pressed.connect(_on_quit_pressed)
        
        # Hide quit button on mobile
        if OS.get_name() == "Android" or OS.get_name() == "iOS":
            quit_button.visible = false

func _input(event):
    # Handle pause input
    if event.is_action_pressed("ui_cancel"):
        if visible:
            hide_pause_menu()
        elif GameManager and GameManager.is_game_active():
            show_pause_menu()

func show_pause_menu():
    if is_paused:
        return
    
    is_paused = true
    visible = true
    
    # Pause the game
    get_tree().paused = true
    
    # Animate appearance
    animate_show()
    
    # Focus first button
    if resume_button:
        resume_button.grab_focus()
    
    AudioManager.play_ui_click_sound()

func hide_pause_menu():
    if not is_paused:
        return
    
    is_paused = false
    
    # Animate disappearance
    await animate_hide()
    
    # Unpause the game
    get_tree().paused = false
    
    # Hide menu
    visible = false

func animate_show():
    # Background fade in
    if background_overlay:
        background_overlay.modulate.a = 0.0
        var bg_tween = create_tween()
        bg_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        bg_tween.tween_property(background_overlay, "modulate:a", 0.8, 0.3)
    
    # Panel slide in
    if pause_panel:
        pause_panel.modulate.a = 0.0
        pause_panel.scale = Vector2(0.8, 0.8)
        
        var panel_tween = create_tween()
        panel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
        panel_tween.set_parallel(true)
        
        panel_tween.tween_property(pause_panel, "modulate:a", 1.0, 0.3)
        panel_tween.tween_property(pause_panel, "scale", Vector2(1.0, 1.0), 0.3)

func animate_hide():
    var tween = create_tween()
    tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
    tween.set_parallel(true)
    
    # Fade out background
    if background_overlay:
        tween.tween_property(background_overlay, "modulate:a", 0.0, 0.2)
    
    # Scale down panel
    if pause_panel:
        tween.tween_property(pause_panel, "modulate:a", 0.0, 0.2)
        tween.tween_property(pause_panel, "scale", Vector2(0.8, 0.8), 0.2)
    
    await tween.finished

# Button handlers
func _on_resume_pressed():
    AudioManager.play_ui_click_sound()
    hide_pause_menu()

func _on_settings_pressed():
    AudioManager.play_ui_click_sound()
    
    # Show settings panel
    var settings_ui = get_tree().get_first_node_in_group("settings_ui")
    if settings_ui and settings_ui.has_method("show_settings"):
        settings_ui.show_settings()

func _on_main_menu_pressed():
    AudioManager.play_ui_click_sound()
    
    # Confirmation dialog
    show_confirmation_dialog(
        "Return to Main Menu?",
        "Your progress will be saved.",
        _confirmed_main_menu
    )

func _on_quit_pressed():
    AudioManager.play_ui_click_sound()
    
    # Confirmation dialog
    show_confirmation_dialog(
        "Quit Game?",
        "Your progress will be saved.",
        _confirmed_quit
    )

func show_confirmation_dialog(title: String, message: String, callback: Callable):
    var dialog = ConfirmationDialog.new()
    dialog.title = title
    dialog.dialog_text = message
    dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
    
    add_child(dialog)
    dialog.confirmed.connect(callback)
    dialog.canceled.connect(func(): dialog.queue_free())
    dialog.popup_centered()

func _confirmed_main_menu():
    # Save game state
    if SaveLoadManager:
        SaveLoadManager.save_game_data()
    
    # Unpause and go to main menu
    get_tree().paused = false
    SceneTransitionManager.change_scene("res://scenes/MainMenu.tscn")

func _confirmed_quit():
    # Save and quit
    if SaveLoadManager:
        SaveLoadManager.save_game_data()
    
    get_tree().quit()

# Public interface
func is_pause_menu_visible() -> bool:
    return visible

func force_hide():
    if visible:
        get_tree().paused = false
        visible = false
        is_paused = false