extends CharacterBody3D

# Minimal working player script
const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Camera reference
@onready var camera = $CameraPivot/Camera3D

func _ready():
    add_to_group("player")
    print("Player ready and working!")

func _physics_process(delta):
    # Add the gravity
    if not is_on_floor():
        velocity.y -= gravity * delta

    # Handle jump
    if Input.is_action_just_pressed("ui_accept") and is_on_floor():
        velocity.y = JUMP_VELOCITY

    # Get the input direction and handle the movement/deceleration
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    if input_dir != Vector2.ZERO:
        velocity.x = input_dir.x * SPEED
        velocity.z = input_dir.y * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

    move_and_slide()
    
    # Shooting
    if Input.is_action_just_pressed("shoot"):
        shoot()
    
    # Debug output
    if Input.is_action_just_pressed("ui_select"):
        print("Player position: ", global_position)

func shoot():
    if not camera:
        return
        
    var space_state = get_viewport().get_world_3d().direct_space_state
    var from = camera.global_position
    var to = from + (-camera.global_transform.basis.z) * 50.0
    
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Bug layer only
    
    var result = space_state.intersect_ray(query)
    
    # Play shoot sound
    if AudioManager:
        AudioManager.play_shoot_sound()
    
    if result:
        var hit_object = result.get("collider")
        if hit_object and hit_object.has_method("hit"):
            hit_object.hit()
            print("Hit bug!")
        else:
            print("Hit something else:", hit_object)
    else:
        print("Shot fired, no hit")