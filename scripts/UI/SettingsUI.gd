extends Control

# Settings UI Manager
@onready var master_volume_slider = $Panel/ScrollContainer/VBoxContainer/AudioSection/MasterVolumeSlider
@onready var music_volume_slider = $Panel/ScrollContainer/VBoxContainer/AudioSection/MusicVolumeSlider
@onready var sfx_volume_slider = $Panel/ScrollContainer/VBoxContainer/AudioSection/SFXVolumeSlider

@onready var graphics_quality_option = $Panel/ScrollContainer/VBoxContainer/GraphicsSection/QualityOption
@onready var vsync_checkbox = $Panel/ScrollContainer/VBoxContainer/GraphicsSection/VSyncCheckbox
@onready var fullscreen_checkbox = $Panel/ScrollContainer/VBoxContainer/GraphicsSection/FullscreenCheckbox

@onready var camera_sensitivity_slider = $Panel/ScrollContainer/VBoxContainer/GameplaySection/CameraSensitivitySlider
@onready var auto_shoot_checkbox = $Panel/ScrollContainer/VBoxContainer/GameplaySection/AutoShootCheckbox
@onready var joystick_size_slider = $Panel/ScrollContainer/VBoxContainer/GameplaySection/JoystickSizeSlider

@onready var language_option = $Panel/ScrollContainer/VBoxContainer/GeneralSection/LanguageOption

# Buttons
@onready var apply_button = $Panel/ButtonContainer/ApplyButton
@onready var reset_button = $Panel/ButtonContainer/ResetButton
@onready var back_button = $Panel/ButtonContainer/BackButton

# Data backup for cancel functionality
var backup_settings: Dictionary = {}

func _ready():
    # Initially hidden
    visible = false
    
    # Connect controls
    connect_controls()
    
    # Load current settings
    load_current_settings()

func connect_controls():
    # Volume sliders
    if master_volume_slider:
        master_volume_slider.value_changed.connect(_on_master_volume_changed)
    
    if music_volume_slider:
        music_volume_slider.value_changed.connect(_on_music_volume_changed)
    
    if sfx_volume_slider:
        sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
    
    # Graphics options
    if graphics_quality_option:
        graphics_quality_option.item_selected.connect(_on_graphics_quality_changed)
    
    if vsync_checkbox:
        vsync_checkbox.toggled.connect(_on_vsync_toggled)
    
    if fullscreen_checkbox:
        fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
    
    # Gameplay options
    if camera_sensitivity_slider:
        camera_sensitivity_slider.value_changed.connect(_on_camera_sensitivity_changed)
    
    if auto_shoot_checkbox:
        auto_shoot_checkbox.toggled.connect(_on_auto_shoot_toggled)
    
    if joystick_size_slider:
        joystick_size_slider.value_changed.connect(_on_joystick_size_changed)
    
    # Language
    if language_option:
        language_option.item_selected.connect(_on_language_changed)
    
    # Buttons
    if apply_button:
        apply_button.pressed.connect(_on_apply_pressed)
    
    if reset_button:
        reset_button.pressed.connect(_on_reset_pressed)
    
    if back_button:
        back_button.pressed.connect(_on_back_pressed)

func load_current_settings():
    # Backup current settings
    backup_settings = SaveLoadManager.settings_data.duplicate()
    
    # Load values into UI
    if master_volume_slider:
        master_volume_slider.value = SaveLoadManager.get_setting("master_volume") * 100
    
    if music_volume_slider:
        music_volume_slider.value = SaveLoadManager.get_setting("music_volume") * 100
    
    if sfx_volume_slider:
        sfx_volume_slider.value = SaveLoadManager.get_setting("sfx_volume") * 100
    
    if graphics_quality_option:
        graphics_quality_option.selected = SaveLoadManager.get_setting("graphics_quality")
    
    if camera_sensitivity_slider:
        camera_sensitivity_slider.value = SaveLoadManager.get_setting("camera_sensitivity") * 100
    
    if auto_shoot_checkbox:
        auto_shoot_checkbox.button_pressed = SaveLoadManager.get_setting("auto_shoot")
    
    # Hide mobile-only settings on desktop
    setup_platform_specific_ui()

func setup_platform_specific_ui():
    var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
    
    # Hide fullscreen on mobile
    if fullscreen_checkbox:
        fullscreen_checkbox.visible = not is_mobile
    
    # Hide joystick size on desktop
    if joystick_size_slider:
        joystick_size_slider.get_parent().visible = is_mobile

# Audio settings
func _on_master_volume_changed(value: float):
    var volume = value / 100.0
    SaveLoadManager.set_setting("master_volume", volume)
    AudioManager.set_master_volume(volume)

func _on_music_volume_changed(value: float):
    var volume = value / 100.0
    SaveLoadManager.set_setting("music_volume", volume)
    AudioManager.set_music_volume(volume)

func _on_sfx_volume_changed(value: float):
    var volume = value / 100.0
    SaveLoadManager.set_setting("sfx_volume", volume)
    AudioManager.set_sfx_volume(volume)
    
    # Play test sound
    AudioManager.play_ui_click_sound()

# Graphics settings
func _on_graphics_quality_changed(index: int):
    SaveLoadManager.set_setting("graphics_quality", index)
    apply_graphics_quality(index)

func apply_graphics_quality(quality: int):
    match quality:
        0:  # Low
            get_viewport().msaa_3d = Viewport.MSAA_DISABLED
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
        1:  # Medium
            get_viewport().msaa_3d = Viewport.MSAA_2X
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
        2:  # High
            get_viewport().msaa_3d = Viewport.MSAA_4X
            get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA

func _on_vsync_toggled(enabled: bool):
    if enabled:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
    else:
        DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_fullscreen_toggled(enabled: bool):
    if enabled:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
    else:
        DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

# Gameplay settings
func _on_camera_sensitivity_changed(value: float):
    var sensitivity = value / 100.0
    SaveLoadManager.set_setting("camera_sensitivity", sensitivity)

func _on_auto_shoot_toggled(enabled: bool):
    SaveLoadManager.set_setting("auto_shoot", enabled)

func _on_joystick_size_changed(value: float):
    var size = value / 100.0
    SaveLoadManager.set_setting("joystick_size", size)
    
    # Update joystick size if in game
    var touch_controls = get_tree().get_first_node_in_group("touch_controls")
    if touch_controls and touch_controls.has_method("update_joystick_size"):
        touch_controls.update_joystick_size(size)

# Language settings
func _on_language_changed(index: int):
    var languages = ["en", "es", "fr", "de", "hi"]  # Add Hindi for Indian players
    if index < languages.size():
        SaveLoadManager.set_setting("language", languages[index])
        # Apply language change (would need localization system)

# Button actions
func _on_apply_pressed():
    AudioManager.play_ui_click_sound()
    SaveLoadManager.save_settings()
    show_confirmation("Settings saved!")

func _on_reset_pressed():
    AudioManager.play_ui_click_sound()
    
    # Confirmation dialog
    var confirmation = ConfirmationDialog.new()
    confirmation.dialog_text = "Reset all settings to defaults?"
    add_child(confirmation)
    confirmation.confirmed.connect(reset_to_defaults)
    confirmation.popup_centered()

func reset_to_defaults():
    # Reset to default values
    SaveLoadManager.settings_data = {
        "master_volume": 1.0,
        "music_volume": 0.8,
        "sfx_volume": 0.8,
        "graphics_quality": 1,
        "auto_shoot": false,
        "camera_sensitivity": 1.0,
        "language": "en"
    }
    
    # Save and reload UI
    SaveLoadManager.save_settings()
    load_current_settings()
    show_confirmation("Settings reset to defaults!")

func _on_back_pressed():
    AudioManager.play_ui_click_sound()
    hide_settings()

func show_settings():
    visible = true
    modulate.a = 0.0
    
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_settings():
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.3)
    tween.tween_callback(func(): visible = false)

func show_confirmation(message: String):
    # Show temporary confirmation message
    var confirmation_label = Label.new()
    confirmation_label.text = message
    confirmation_label.add_theme_font_size_override("font_size", 20)
    confirmation_label.modulate = Color.GREEN
    confirmation_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
    confirmation_label.position.y += 50
    
    add_child(confirmation_label)
    
    # Fade out after 2 seconds
    var tween = create_tween()
    tween.tween_delay(2.0)
    tween.tween_property(confirmation_label, "modulate:a", 0.0, 0.5)
    tween.tween_callback(func(): confirmation_label.queue_free())

func _input(event):
    # Handle back button (Android)
    if event.is_action_pressed("ui_cancel") and visible:
        _on_back_pressed()