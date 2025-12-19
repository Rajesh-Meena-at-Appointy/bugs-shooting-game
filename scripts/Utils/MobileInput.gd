extends Node

# MobileInput - Mobile-specific input handling utilities
class_name MobileInput

# Touch tracking
var active_touches: Dictionary = {}
var gesture_start_positions: Dictionary = {}

# Gesture detection
var pinch_start_distance: float = 0.0
var pinch_current_distance: float = 0.0
var is_pinching: bool = false

# Swipe detection
var swipe_threshold: float = 100.0
var swipe_time_limit: float = 0.5
var swipe_start_time: float = 0.0
var swipe_start_position: Vector2 = Vector2.ZERO

# Double tap detection
var double_tap_threshold: float = 0.3
var last_tap_time: float = 0.0
var last_tap_position: Vector2 = Vector2.ZERO
var game_timer: float = 0.0

# Signals
signal touch_started(position: Vector2, index: int)
signal touch_ended(position: Vector2, index: int)
signal touch_moved(position: Vector2, index: int, relative: Vector2)
signal swipe_detected(direction: Vector2, strength: float)
signal pinch_detected(scale: float)
signal double_tap_detected(position: Vector2)

func _ready():
    # Only active on mobile devices
    if not is_mobile_device():
        set_process(false)
        return

func _process(delta):
    game_timer += delta

func _input(event):
    if not is_mobile_device():
        return
    
    if event is InputEventScreenTouch:
        handle_touch_event(event)
    elif event is InputEventScreenDrag:
        handle_drag_event(event)

func handle_touch_event(event: InputEventScreenTouch):
    var index = event.index
    var position = event.position
    
    if event.pressed:
        # Touch started
        active_touches[index] = {
            "position": position,
            "start_position": position,
            "start_time": game_timer
        }
        
        touch_started.emit(position, index)
        
        # Check for double tap
        check_double_tap(position)
        
        # Start gesture tracking
        if active_touches.size() == 2:
            start_gesture_tracking()
    
    else:
        # Touch ended
        if active_touches.has(index):
            var touch_data = active_touches[index]
            touch_ended.emit(position, index)
            
            # Check for swipe
            check_swipe_gesture(touch_data, position)
            
            # Remove from active touches
            active_touches.erase(index)
        
        # End gesture tracking
        if active_touches.size() < 2:
            end_gesture_tracking()

func handle_drag_event(event: InputEventScreenDrag):
    var index = event.index
    var position = event.position
    
    if active_touches.has(index):
        var old_position = active_touches[index]["position"]
        active_touches[index]["position"] = position
        
        var relative = position - old_position
        touch_moved.emit(position, index, relative)
        
        # Update gesture tracking
        if active_touches.size() == 2:
            update_gesture_tracking()

func check_double_tap(position: Vector2):
    var current_time = game_timer
    var time_diff = current_time - last_tap_time
    var distance = position.distance_to(last_tap_position)
    
    if time_diff <= double_tap_threshold and distance <= 50.0:
        double_tap_detected.emit(position)
    
    last_tap_time = current_time
    last_tap_position = position

func check_swipe_gesture(touch_data: Dictionary, end_position: Vector2):
    var start_pos = touch_data["start_position"]
    var start_time = touch_data["start_time"]
    var current_time = game_timer
    
    var distance = start_pos.distance_to(end_position)
    var time_diff = current_time - start_time
    
    if distance >= swipe_threshold and time_diff <= swipe_time_limit:
        var direction = (end_position - start_pos).normalized()
        var strength = distance / swipe_threshold
        swipe_detected.emit(direction, strength)

func start_gesture_tracking():
    if active_touches.size() != 2:
        return
    
    var touches = active_touches.values()
    var pos1 = touches[0]["position"]
    var pos2 = touches[1]["position"]
    
    pinch_start_distance = pos1.distance_to(pos2)
    is_pinching = true

func update_gesture_tracking():
    if not is_pinching or active_touches.size() != 2:
        return
    
    var touches = active_touches.values()
    var pos1 = touches[0]["position"]
    var pos2 = touches[1]["position"]
    
    pinch_current_distance = pos1.distance_to(pos2)
    
    if pinch_start_distance > 0:
        var scale = pinch_current_distance / pinch_start_distance
        pinch_detected.emit(scale)

func end_gesture_tracking():
    is_pinching = false
    pinch_start_distance = 0.0
    pinch_current_distance = 0.0

# Utility functions
func is_mobile_device() -> bool:
    var platform = OS.get_name()
    return platform == "Android" or platform == "iOS"

func get_active_touch_count() -> int:
    return active_touches.size()

func get_primary_touch_position() -> Vector2:
    if active_touches.size() > 0:
        var first_touch = active_touches.values()[0]
        return first_touch["position"]
    return Vector2.ZERO

func get_touch_positions() -> Array[Vector2]:
    var positions: Array[Vector2] = []
    for touch_data in active_touches.values():
        positions.append(touch_data["position"])
    return positions

# Virtual joystick helper
func create_virtual_joystick(center: Vector2, radius: float) -> Dictionary:
    return {
        "center": center,
        "radius": radius,
        "is_active": false,
        "touch_index": -1,
        "current_offset": Vector2.ZERO
    }

func update_virtual_joystick(joystick: Dictionary, touch_pos: Vector2, touch_index: int) -> Vector2:
    if not joystick["is_active"]:
        # Start joystick interaction
        var distance = joystick["center"].distance_to(touch_pos)
        if distance <= joystick["radius"]:
            joystick["is_active"] = true
            joystick["touch_index"] = touch_index
    
    if joystick["is_active"] and joystick["touch_index"] == touch_index:
        # Update joystick
        var offset = touch_pos - joystick["center"]
        
        # Clamp to radius
        if offset.length() > joystick["radius"]:
            offset = offset.normalized() * joystick["radius"]
        
        joystick["current_offset"] = offset
        
        # Return normalized input (-1 to 1)
        return offset / joystick["radius"]
    
    return Vector2.ZERO

func release_virtual_joystick(joystick: Dictionary, touch_index: int):
    if joystick["touch_index"] == touch_index:
        joystick["is_active"] = false
        joystick["touch_index"] = -1
        joystick["current_offset"] = Vector2.ZERO

# Haptic feedback
func trigger_haptic_light():
    if is_mobile_device():
        trigger_haptic(0.1, 0.1)

func trigger_haptic_medium():
    if is_mobile_device():
        trigger_haptic(0.3, 0.2)

func trigger_haptic_heavy():
    if is_mobile_device():
        trigger_haptic(0.6, 0.3)

func trigger_haptic(intensity: float, duration: float = 0.1):
    if not is_mobile_device():
        return
    
    # Use controller vibration if available
    var joypads = Input.get_connected_joypads()
    if joypads.size() > 0:
        Input.start_joy_vibration(joypads[0], intensity, intensity, duration)

# Screen orientation
func lock_landscape():
    if is_mobile_device():
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_LANDSCAPE)

func lock_portrait():
    if is_mobile_device():
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_PORTRAIT)

func unlock_orientation():
    if is_mobile_device():
        DisplayServer.screen_set_orientation(DisplayServer.SCREEN_SENSOR_LANDSCAPE)

# Device info
func get_screen_dpi() -> float:
    return DisplayServer.screen_get_dpi()

func get_safe_area() -> Rect2:
    # Get safe area avoiding notches and system UI
    var viewport_size = get_viewport().get_visible_rect().size
    
    if is_mobile_device():
        # Account for system UI and notches
        var safe_margin = 40
        return Rect2(
            Vector2(safe_margin, safe_margin),
            viewport_size - Vector2(safe_margin * 2, safe_margin * 2)
        )
    
    return Rect2(Vector2.ZERO, viewport_size)

func is_tablet() -> bool:
    if not is_mobile_device():
        return false
    
    var viewport_size = get_viewport().get_visible_rect().size
    var diagonal = sqrt(viewport_size.x * viewport_size.x + viewport_size.y * viewport_size.y)
    var dpi = get_screen_dpi()
    
    # Estimate physical diagonal in inches
    var physical_diagonal = diagonal / dpi
    
    # Consider 7+ inches as tablet
    return physical_diagonal >= 7.0