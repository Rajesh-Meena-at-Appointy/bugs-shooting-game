extends Control

# MobileUIManager - Unified mobile interface controller
class_name MobileUIManager

# UI References
@onready var touch_controls = $TouchControls
@onready var hud = $HUD
@onready var pause_menu = $PauseMenu
@onready var settings_panel = $SettingsPanel

# Mobile-specific elements
@onready var virtual_joystick = $TouchControls/VirtualJoystick
@onready var fire_button = $TouchControls/FireButton
@onready var pause_button = $HUD/PauseButton
@onready var camera_touch_area = $TouchControls/CameraTouchArea

# Input state
var is_mobile_device: bool = false
var touch_enabled: bool = true
var ui_scale_factor: float = 1.0

# Settings
@export var auto_hide_ui: bool = false
@export var ui_fade_delay: float = 3.0
var ui_hide_timer: float = 0.0

func _ready():
    # Detect mobile platform
    detect_mobile_platform()
    
    # Setup mobile UI
    setup_mobile_interface()
    
    # Connect signals
    connect_ui_signals()
    
    # Apply mobile optimizations
    apply_mobile_optimizations()

func detect_mobile_platform():
    var platform = OS.get_name()
    is_mobile_device = platform == "Android" or platform == "iOS"
    
    # Show/hide mobile controls
    if touch_controls:
        touch_controls.visible = is_mobile_device
    
    # Adjust UI for platform
    adjust_ui_for_platform()

func adjust_ui_for_platform():
    if is_mobile_device:
        # Mobile optimizations
        setup_mobile_layout()
        enable_mobile_features()
    else:
        # Desktop optimizations
        setup_desktop_layout()
        disable_mobile_features()

func setup_mobile_layout():
    # Scale UI elements for touch
    ui_scale_factor = get_mobile_scale_factor()
    apply_ui_scaling()
    
    # Position elements for landscape orientation
    position_mobile_elements()
    
    # Show mobile-specific buttons
    show_mobile_ui_elements()

func setup_desktop_layout():
    # Hide mobile controls
    hide_mobile_ui_elements()
    
    # Show desktop-specific elements
    show_desktop_ui_elements()

func get_mobile_scale_factor() -> float:
    var viewport_size = get_viewport().get_visible_rect().size
    var base_resolution = Vector2(1280, 720)
    
    # Calculate scale based on screen density
    var scale_x = viewport_size.x / base_resolution.x
    var scale_y = viewport_size.y / base_resolution.y
    
    return min(scale_x, scale_y) * 1.2  # 20% larger for touch

func apply_ui_scaling():
    # Scale touch controls
    if virtual_joystick:
        virtual_joystick.custom_minimum_size *= ui_scale_factor
    
    if fire_button:
        fire_button.custom_minimum_size = Vector2(120, 120) * ui_scale_factor
    
    if pause_button:
        pause_button.custom_minimum_size = Vector2(60, 60) * ui_scale_factor

func position_mobile_elements():
    var safe_area = get_safe_area()
    
    # Position virtual joystick (bottom-left)
    if virtual_joystick:
        virtual_joystick.position = Vector2(
            safe_area.position.x + 50,
            safe_area.end.y - virtual_joystick.size.y - 50
        )
    
    # Position fire button (bottom-right)
    if fire_button:
        fire_button.position = Vector2(
            safe_area.end.x - fire_button.size.x - 50,
            safe_area.end.y - fire_button.size.y - 50
        )
    
    # Position pause button (top-right)
    if pause_button:
        pause_button.position = Vector2(
            safe_area.end.x - pause_button.size.x - 20,
            safe_area.position.y + 20
        )

func get_safe_area() -> Rect2:
    var viewport_rect = get_viewport().get_visible_rect()
    
    # Account for notches and system UI on mobile
    if is_mobile_device:
        var safe_margin = 40  # Safe margin for system UI
        return Rect2(
            Vector2(safe_margin, safe_margin),
            viewport_rect.size - Vector2(safe_margin * 2, safe_margin * 2)
        )
    
    return viewport_rect

func setup_mobile_interface():
    if not is_mobile_device:
        return
    
    # Configure joystick
    setup_virtual_joystick()
    
    # Configure fire button
    setup_fire_button()
    
    # Configure camera touch area
    setup_camera_touch_area()
    
    # Setup gesture recognition
    setup_gesture_recognition()

func setup_virtual_joystick():
    if not virtual_joystick:
        return
    
    # Configure joystick properties
    virtual_joystick.joystick_radius = 80.0 * ui_scale_factor
    virtual_joystick.dead_zone = 0.1
    
    # Connect joystick signals
    if virtual_joystick.has_signal("joystick_moved"):
        virtual_joystick.joystick_moved.connect(_on_joystick_moved)

func setup_fire_button():
    if not fire_button:
        return
    
    # Style fire button
    fire_button.text = "🔫"
    fire_button.add_theme_font_size_override("font_size", int(48 * ui_scale_factor))
    
    # Connect fire button
    fire_button.pressed.connect(_on_fire_button_pressed)
    fire_button.button_down.connect(_on_fire_button_down)
    fire_button.button_up.connect(_on_fire_button_up)

func setup_camera_touch_area():
    if not camera_touch_area:
        return
    
    # Make camera area cover right side of screen
    var viewport_size = get_viewport().get_visible_rect().size
    camera_touch_area.size = Vector2(viewport_size.x * 0.6, viewport_size.y)
    camera_touch_area.position = Vector2(viewport_size.x * 0.4, 0)
    
    # Connect touch events
    camera_touch_area.gui_input.connect(_on_camera_touch_input)

func setup_gesture_recognition():
    # Setup gesture detection for mobile
    # (Pinch to zoom, two-finger gestures, etc.)
    pass

func connect_ui_signals():
    # Connect pause button
    if pause_button:
        pause_button.pressed.connect(_on_pause_pressed)
    
    # Connect to game events
    if GameManager:
        GameManager.game_started.connect(_on_game_started)
        GameManager.game_over.connect(_on_game_over)

func apply_mobile_optimizations():
    if not is_mobile_device:
        return
    
    # Battery optimization
    Engine.max_fps = 60
    
    # Input optimization
    Input.set_use_accumulated_input(false)
    
    # Performance settings
    get_viewport().snap_2d_transforms_to_pixel = true
    get_viewport().snap_2d_vertices_to_pixel = true

# Input handlers
func _on_joystick_moved(offset: Vector2):
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("set_movement_input"):
        player.set_movement_input(offset)

func _on_fire_button_pressed():
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("mobile_shoot"):
        player.mobile_shoot()

func _on_fire_button_down():
    # Haptic feedback on supported devices
    trigger_haptic_feedback(0.1)

func _on_fire_button_up():
    # Light haptic feedback
    trigger_haptic_feedback(0.05)

func _on_camera_touch_input(event: InputEvent):
    if not event is InputEventScreenDrag:
        return
    
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("set_camera_input"):
        player.set_camera_input(event.relative)

func _on_pause_pressed():
    if GameManager and GameManager.has_method("pause_game"):
        GameManager.pause_game()

# Game event handlers
func _on_game_started():
    show_game_ui()
    hide_menu_ui()

func _on_game_over():
    show_game_over_ui()

# UI visibility management
func show_mobile_ui_elements():
    if virtual_joystick:
        virtual_joystick.visible = true
    if fire_button:
        fire_button.visible = true
    if camera_touch_area:
        camera_touch_area.visible = true

func hide_mobile_ui_elements():
    if virtual_joystick:
        virtual_joystick.visible = false
    if fire_button:
        fire_button.visible = false
    if camera_touch_area:
        camera_touch_area.visible = false

func show_desktop_ui_elements():
    # Show desktop-specific UI
    pass

func show_game_ui():
    if hud:
        hud.visible = true
    if touch_controls:
        touch_controls.visible = is_mobile_device

func hide_menu_ui():
    if pause_menu:
        pause_menu.visible = false

func show_game_over_ui():
    # Show game over screen
    pass

# Auto-hide UI functionality
func _input(event):
    if auto_hide_ui and is_mobile_device:
        # Reset hide timer on any input
        ui_hide_timer = 0.0
        show_ui_elements()

func _process(delta):
    if auto_hide_ui and is_mobile_device:
        ui_hide_timer += delta
        
        if ui_hide_timer >= ui_fade_delay:
            hide_ui_elements()

func show_ui_elements():
    if hud:
        var tween = create_tween()
        tween.tween_property(hud, "modulate:a", 1.0, 0.3)

func hide_ui_elements():
    if hud:
        var tween = create_tween()
        tween.tween_property(hud, "modulate:a", 0.3, 0.5)

# Haptic feedback
func trigger_haptic_feedback(intensity: float):
    if is_mobile_device and Input.get_connected_joypads().size() > 0:
        # Trigger vibration if supported
        Input.start_joy_vibration(0, intensity, intensity, 0.1)

# Public interface
func set_ui_scale(scale: float):
    ui_scale_factor = scale
    apply_ui_scaling()

func toggle_touch_controls():
    touch_enabled = not touch_enabled
    if touch_controls:
        touch_controls.visible = touch_enabled and is_mobile_device

func is_mobile() -> bool:
    return is_mobile_device

func update_joystick_size(size_multiplier: float):
    if virtual_joystick:
        virtual_joystick.joystick_radius = 80.0 * size_multiplier