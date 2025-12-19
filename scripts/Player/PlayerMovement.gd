extends Node

# PlayerMovement - Dedicated movement controller
class_name PlayerMovement

@export var speed: float = 5.0
@export var acceleration: float = 10.0
@export var deceleration: float = 10.0
@export var air_acceleration: float = 2.0

# References
@onready var player_body = get_parent()
var input_vector: Vector2 = Vector2.ZERO

# Movement state
var is_moving: bool = false
var movement_velocity: Vector3 = Vector3.ZERO

func _ready():
    if not player_body is CharacterBody3D:
        push_error("PlayerMovement must be child of CharacterBody3D")

func _physics_process(delta):
    handle_movement(delta)

func handle_movement(delta):
    # Get movement input
    get_movement_input()
    
    # Calculate movement
    calculate_movement(delta)
    
    # Apply movement to player body
    apply_movement()

func get_movement_input():
    # Check if mobile or desktop
    var is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
    
    if is_mobile:
        # Mobile input handled by TouchControls
        # input_vector is set by set_movement_input()
        pass
    else:
        # Desktop input
        input_vector = Input.get_vector("move_left", "move_right", "move_forward", "move_back")

func calculate_movement(delta):
    # Target velocity based on input and camera direction
    var target_velocity = Vector3.ZERO
    
    if input_vector.length() > 0.1:
        var camera_basis = get_camera_basis()
        var forward = -camera_basis.z
        var right = camera_basis.x
        
        # Remove Y component to keep movement on ground
        forward.y = 0
        right.y = 0
        forward = forward.normalized()
        right = right.normalized()
        
        target_velocity = (forward * -input_vector.y + right * input_vector.x) * speed
        is_moving = true
    else:
        is_moving = false
    
    # Interpolate to target velocity
    var accel = acceleration if is_moving else deceleration
    if not player_body.is_on_floor():
        accel = air_acceleration
    
    movement_velocity = movement_velocity.move_toward(target_velocity, accel * delta)

func apply_movement():
    if player_body:
        player_body.velocity.x = movement_velocity.x
        player_body.velocity.z = movement_velocity.z

func get_camera_basis() -> Basis:
    var camera = get_viewport().get_camera_3d()
    if camera:
        return camera.global_transform.basis
    return Basis.IDENTITY

# Public interface for external control
func set_movement_input(movement: Vector2):
    input_vector = movement

func get_movement_vector() -> Vector2:
    return input_vector

func get_movement_velocity() -> Vector3:
    return movement_velocity

func is_player_moving() -> bool:
    return is_moving

# Movement modifiers
func set_speed_multiplier(multiplier: float):
    speed = speed * multiplier

func add_impulse(impulse: Vector3):
    movement_velocity += impulse

func stop_movement():
    input_vector = Vector2.ZERO
    movement_velocity = Vector3.ZERO