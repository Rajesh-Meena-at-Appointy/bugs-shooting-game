extends CharacterBody3D

# Simple player script for testing
@export var speed: float = 5.0

func _ready():
    print("Simple Player ready!")

func _physics_process(delta):
    # Simple movement
    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    
    if input_dir != Vector2.ZERO:
        velocity.x = input_dir.x * speed
        velocity.z = input_dir.y * speed
    else:
        velocity.x = move_toward(velocity.x, 0, speed * delta * 3)
        velocity.z = move_toward(velocity.z, 0, speed * delta * 3)
    
    # Add gravity
    if not is_on_floor():
        velocity.y += get_gravity().y * delta
    
    move_and_slide()
    
    # Debug print
    if Input.is_action_just_pressed("ui_accept"):
        print("Player position: ", global_position)