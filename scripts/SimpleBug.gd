extends CharacterBody3D

const SPEED = 2.0
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var player_position = Vector3.ZERO

func _ready():
    add_to_group("bugs")

func _physics_process(delta):
    # Add gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Find player
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player_position = player.global_position
        
        # Move toward player
        var direction = (player_position - global_position).normalized()
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    
    move_and_slide()

func hit():
    print("Bug hit!")
    queue_free()

func _on_timer_timeout():
    # Simple floating movement
    position.y += sin(Time.get_ticks_msec() * 0.001) * 0.1