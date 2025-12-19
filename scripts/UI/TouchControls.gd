extends Control

# Virtual Joystick for movement
@onready var joystick_background = $MovementJoystick/Background
@onready var joystick_knob = $MovementJoystick/Knob
@onready var fire_button = $FireButton

# Touch areas
@onready var movement_area = $MovementJoystick
@onready var camera_area = $CameraArea  # Right side of screen for camera look

# Joystick settings
@export var joystick_radius: float = 80.0
var joystick_center: Vector2
var is_joystick_pressed: bool = false
var movement_vector: Vector2 = Vector2.ZERO

# Camera look
var is_camera_dragging: bool = false
var last_camera_position: Vector2
var camera_sensitivity: float = 2.0

# Player reference
var player: Node3D

func _ready():
    # Get player reference
    player = get_tree().get_first_node_in_group("player")
    
    # Set up joystick
    setup_joystick()
    
    # Set up fire button
    setup_fire_button()
    
    # Set up camera area
    setup_camera_area()
    
    # Only show on mobile
    var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
    visible = is_mobile

func setup_joystick():
    if not joystick_background or not joystick_knob:
        return
    
    # Set joystick center
    joystick_center = joystick_background.position + joystick_background.size / 2
    
    # Connect joystick input
    movement_area.gui_input.connect(_on_joystick_input)

func setup_fire_button():
    if fire_button:
        fire_button.pressed.connect(_on_fire_button_pressed)
        # Make fire button larger for easier touch
        fire_button.custom_minimum_size = Vector2(120, 120)

func setup_camera_area():
    if not camera_area:
        # Create camera area if it doesn't exist
        camera_area = Control.new()
        camera_area.name = "CameraArea"
        camera_area.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
        camera_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        add_child(camera_area)
    
    camera_area.gui_input.connect(_on_camera_input)

func _on_joystick_input(event: InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed:
            is_joystick_pressed = true
            update_joystick(event.position)
        else:
            is_joystick_pressed = false
            reset_joystick()
    
    elif event is InputEventScreenDrag and is_joystick_pressed:
        update_joystick(event.position)

func update_joystick(touch_position: Vector2):
    # Convert to local position
    var local_position = movement_area.to_local(touch_position)
    
    # Calculate offset from center
    var offset = local_position - (joystick_background.position + joystick_background.size / 2)
    
    # Limit to joystick radius
    if offset.length() > joystick_radius:
        offset = offset.normalized() * joystick_radius
    
    # Update knob position
    joystick_knob.position = joystick_background.position + joystick_background.size / 2 + offset - joystick_knob.size / 2
    
    # Calculate movement vector (-1 to 1)
    movement_vector = offset / joystick_radius
    
    # Send to player
    if player and player.has_method("set_movement_input"):
        player.set_movement_input(movement_vector)

func reset_joystick():
    # Reset knob to center
    if joystick_knob and joystick_background:
        joystick_knob.position = joystick_background.position + joystick_background.size / 2 - joystick_knob.size / 2
    
    movement_vector = Vector2.ZERO
    
    # Send to player
    if player and player.has_method("set_movement_input"):
        player.set_movement_input(Vector2.ZERO)

func _on_camera_input(event: InputEvent):
    if event is InputEventScreenTouch:
        if event.pressed:
            is_camera_dragging = true
            last_camera_position = event.position
        else:
            is_camera_dragging = false
    
    elif event is InputEventScreenDrag and is_camera_dragging:
        var delta = event.position - last_camera_position
        last_camera_position = event.position
        
        # Send camera rotation to player
        if player and player.has_method("set_camera_input"):
            player.set_camera_input(delta * camera_sensitivity)

func _on_fire_button_pressed():
    if player and player.has_method("mobile_shoot"):
        player.mobile_shoot()

# Visual feedback for controls
func _draw():
    if not is_joystick_pressed:
        return
    
    # Draw joystick boundary (optional)
    # draw_circle(joystick_center, joystick_radius, Color.WHITE * 0.2)