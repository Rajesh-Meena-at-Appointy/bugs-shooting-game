extends CanvasLayer

# Touch controls
@onready var joystick_base = $TouchUI/LeftSide/VirtualJoystick/JoystickBase
@onready var joystick_knob = $TouchUI/LeftSide/VirtualJoystick/JoystickKnob
@onready var shoot_button = $TouchUI/RightSide/ShootButton

var is_touching_joystick = false
var joystick_center: Vector2
var joystick_radius = 75.0
var movement_vector = Vector2.ZERO
var is_shooting = false

signal movement_input(direction: Vector2)
signal shoot_pressed
signal shoot_released

func _ready():
    add_to_group("touch_controls")
    
    # Only show on mobile devices
    if not is_mobile_device():
        visible = false
        return
    
    joystick_center = joystick_base.global_position + joystick_base.size / 2
    
    # Make joystick base circular
    joystick_base.color = Color(0.2, 0.2, 0.2, 0.5)
    
    # Make knob circular  
    joystick_knob.color = Color(0.8, 0.8, 0.8, 0.8)

func is_mobile_device() -> bool:
    return OS.get_name() == "Android" or OS.get_name() == "iOS"

func _input(event):
    if not visible:
        return
        
    if event is InputEventScreenTouch or event is InputEventScreenDrag:
        handle_touch_input(event)

func handle_touch_input(event):
    var touch_pos = event.position
    
    # Check if touching joystick area
    var joystick_distance = touch_pos.distance_to(joystick_center)
    
    if event is InputEventScreenTouch:
        if event.pressed:
            if joystick_distance <= joystick_radius:
                is_touching_joystick = true
                update_joystick(touch_pos)
        else:
            if is_touching_joystick:
                is_touching_joystick = false
                reset_joystick()
    
    elif event is InputEventScreenDrag and is_touching_joystick:
        update_joystick(touch_pos)

func update_joystick(touch_pos: Vector2):
    var offset = touch_pos - joystick_center
    var distance = offset.length()
    
    if distance <= joystick_radius:
        joystick_knob.global_position = touch_pos - joystick_knob.size / 2
        movement_vector = offset / joystick_radius
    else:
        var clamped_offset = offset.normalized() * joystick_radius
        joystick_knob.global_position = (joystick_center + clamped_offset) - joystick_knob.size / 2
        movement_vector = offset.normalized()
    
    # Emit movement signal
    movement_input.emit(movement_vector)

func reset_joystick():
    joystick_knob.global_position = joystick_center - joystick_knob.size / 2
    movement_vector = Vector2.ZERO
    movement_input.emit(Vector2.ZERO)

func _on_shoot_button_down():
    is_shooting = true
    shoot_pressed.emit()

func _on_shoot_button_up():
    is_shooting = false
    shoot_released.emit()

func get_movement_vector() -> Vector2:
    return movement_vector

func get_is_shooting() -> bool:
    return is_shooting