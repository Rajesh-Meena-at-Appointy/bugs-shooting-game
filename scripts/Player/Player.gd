extends CharacterBody3D

# Movement settings
@export var speed: float = 5.0
@export var mouse_sensitivity: float = 0.002

# Camera references
@onready var camera_pivot = $CameraPivot
@onready var camera = $CameraPivot/Camera3D

# Mobile touch controls
var is_mobile = false
var touch_movement = Vector2.ZERO
var camera_rotation = Vector2.ZERO

# Shooting
var can_shoot = true
@export var shoot_cooldown = 0.2
var shoot_timer = 0.0

# Signals
signal bug_shot(score_points: int)

func _ready():
    # Check if on mobile platform
    is_mobile = OS.get_name() == "Android" or OS.get_name() == "iOS"
    
    if not is_mobile:
        # Capture mouse on desktop
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
    # Desktop mouse look
    if not is_mobile and event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotate_camera(event.relative * -mouse_sensitivity)
    
    # Shooting input (desktop)
    if event.is_action_pressed("shoot") and can_shoot:
        shoot()

func _physics_process(delta):
    # Handle shooting cooldown
    if not can_shoot:
        shoot_timer += delta
        if shoot_timer >= shoot_cooldown:
            can_shoot = true
            shoot_timer = 0.0
    
    # Movement input
    var input_dir = Vector2.ZERO
    
    if is_mobile:
        # Use touch movement from UI
        input_dir = touch_movement
        # Apply camera rotation from touch
        rotate_camera(camera_rotation * delta)
        camera_rotation = Vector2.ZERO  # Reset after applying
    else:
        # Desktop WASD movement
        input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    
    # Calculate movement direction based on camera
    var direction = Vector3.ZERO
    if input_dir != Vector2.ZERO:
        direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    
    # Apply movement
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    
    # Apply gravity
    if not is_on_floor():
        velocity.y += get_gravity().y * delta
    
    # Move the player
    move_and_slide()

func rotate_camera(mouse_delta: Vector2):
    # Horizontal rotation (Y-axis)
    rotate_y(mouse_delta.x)
    
    # Vertical rotation (X-axis) - limit to prevent over-rotation
    camera_pivot.rotate_x(mouse_delta.y)
    camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, -1.5, 1.5)

func shoot():
    if not can_shoot:
        return
    
    can_shoot = false
    
    # Create raycast from camera
    var space_state = get_world_3d().direct_space_state
    var from = camera.global_position
    var to = from + camera.global_transform.basis.z * -50  # 50 units forward
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Bug layer (set bugs to collision layer 2)
    
    var result = space_state.intersect_ray(query)
    
    if result:
        var hit_object = result.get("collider")
        if hit_object and hit_object.has_method("hit"):
            hit_object.hit()
            # Emit signal for score
            bug_shot.emit(10)  # 10 points per bug
    
    # Play shoot sound
    AudioManager.play_shoot_sound()

# Mobile touch input functions (called from UI)
func set_movement_input(movement: Vector2):
    touch_movement = movement

func set_camera_input(rotation: Vector2):
    camera_rotation = rotation * mouse_sensitivity * 50  # Adjust sensitivity

func mobile_shoot():
    if can_shoot:
        shoot()

func _unhandled_input(event):
    # Escape to release mouse (desktop only)
    if event.is_action_pressed("ui_cancel") and not is_mobile:
        if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
        else:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)