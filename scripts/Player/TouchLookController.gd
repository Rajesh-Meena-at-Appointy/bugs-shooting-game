extends Node

# TouchLookController - Dedicated camera look control
class_name TouchLookController

@export var mouse_sensitivity: float = 0.002
@export var touch_sensitivity: float = 0.003
@export var smoothing: float = 10.0
@export var max_pitch: float = 90.0

# Camera references
@onready var camera_pivot = get_parent().get_node("CameraPivot")
@onready var camera = get_parent().get_node("CameraPivot/Camera3D")

# Input tracking
var mouse_delta: Vector2 = Vector2.ZERO
var touch_delta: Vector2 = Vector2.ZERO
var target_rotation: Vector2 = Vector2.ZERO
var current_rotation: Vector2 = Vector2.ZERO

# Platform detection
var is_mobile: bool = false

func _ready():
    is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
    
    if not is_mobile:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    if not is_mobile and event is InputEventMouseMotion:
        handle_mouse_input(event.relative)

func _process(delta):
    # Apply look rotation with smoothing
    apply_look_rotation(delta)

func handle_mouse_input(relative: Vector2):
    mouse_delta = relative * mouse_sensitivity
    add_look_input(mouse_delta)

func handle_touch_input(delta: Vector2):
    touch_delta = delta * touch_sensitivity
    add_look_input(touch_delta)

func add_look_input(delta: Vector2):
    target_rotation.x -= delta.y
    target_rotation.y -= delta.x
    
    # Clamp vertical rotation
    target_rotation.x = clamp(target_rotation.x, -deg_to_rad(max_pitch), deg_to_rad(max_pitch))

func apply_look_rotation(delta):
    # Smooth interpolation to target
    current_rotation = current_rotation.lerp(target_rotation, smoothing * delta)
    
    # Apply rotations
    if camera_pivot:
        camera_pivot.rotation.x = current_rotation.x
    
    var player_body = get_parent()
    if player_body:
        player_body.rotation.y = current_rotation.y

# Public interface
func set_camera_input(delta: Vector2):
    handle_touch_input(delta)

func get_camera_forward() -> Vector3:
    if camera:
        return -camera.global_transform.basis.z
    return Vector3.FORWARD

func get_camera_right() -> Vector3:
    if camera:
        return camera.global_transform.basis.x
    return Vector3.RIGHT

func reset_camera():
    target_rotation = Vector2.ZERO
    current_rotation = Vector2.ZERO

func set_sensitivity(sensitivity: float):
    mouse_sensitivity = sensitivity * 0.002
    touch_sensitivity = sensitivity * 0.003

func shake_camera(intensity: float):
    if not camera:
        return
    
    var shake_offset = Vector3(
        randf_range(-intensity, intensity),
        randf_range(-intensity, intensity),
        randf_range(-intensity, intensity)
    )
    
    camera.position = shake_offset
    
    # Reset after short time
    var tween = create_tween()
    tween.tween_property(camera, "position", Vector3.ZERO, 0.1)