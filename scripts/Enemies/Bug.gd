extends CharacterBody3D

# Bug properties
@export var speed: float = 2.0
@export var health: int = 1
@export var score_value: int = 10

# Target references
var food_target: Node3D
var player_target: Node3D
var current_target: Node3D

# Animation and effects
var is_dying = false
@onready var mesh_instance = $MeshInstance3D

# Movement
var target_position: Vector3
var random_offset: Vector3

# Bug behavior
enum BugState { MOVING_TO_FOOD, MOVING_TO_PLAYER, IDLE, DYING }
var current_state = BugState.MOVING_TO_FOOD

func _ready():
    # Find targets in the scene
    food_target = get_tree().get_first_node_in_group("food")
    player_target = get_tree().get_first_node_in_group("player")
    
    # Set collision layer for shooting detection
    collision_layer = 2  # Bug layer
    collision_mask = 1   # World layer
    
    # Add to bug group for easy reference
    add_to_group("bugs")
    
    # Set initial target
    set_target(food_target)
    
    # Add some random offset to avoid all bugs moving in same line
    random_offset = Vector3(
        randf_range(-0.5, 0.5),
        0,
        randf_range(-0.5, 0.5)
    )
    
    # Random scale for variety (0.8 to 1.2)
    var random_scale = randf_range(0.8, 1.2)
    scale = Vector3.ONE * random_scale

func _physics_process(delta):
    if is_dying:
        return
    
    # Update behavior based on state
    update_bug_behavior()
    
    # Move towards target
    move_towards_target(delta)
    
    # Apply movement
    move_and_slide()

func update_bug_behavior():
    # Simple AI: Move to food primarily, sometimes chase player
    if food_target and player_target:
        var distance_to_food = global_position.distance_to(food_target.global_position)
        var distance_to_player = global_position.distance_to(player_target.global_position)
        
        # If player is very close (within 3 units), sometimes chase player
        if distance_to_player < 3.0 and randf() < 0.3:
            if current_state != BugState.MOVING_TO_PLAYER:
                set_target(player_target)
                current_state = BugState.MOVING_TO_PLAYER
        else:
            # Default behavior: move to food
            if current_state != BugState.MOVING_TO_FOOD:
                set_target(food_target)
                current_state = BugState.MOVING_TO_FOOD

func set_target(target: Node3D):
    current_target = target
    if target:
        target_position = target.global_position + random_offset

func move_towards_target(delta):
    if not current_target:
        return
    
    # Update target position (in case target moved)
    target_position = current_target.global_position + random_offset
    
    # Calculate direction to target
    var direction = (target_position - global_position).normalized()
    direction.y = 0  # Keep movement on ground level
    
    # Move towards target
    velocity.x = direction.x * speed
    velocity.z = direction.z * speed
    
    # Apply gravity
    if not is_on_floor():
        velocity.y += get_gravity().y * delta
    
    # Rotate to face movement direction
    if direction.length() > 0.1:
        look_at(global_position + direction, Vector3.UP)

func hit():
    if is_dying:
        return
    
    is_dying = true
    
    # Cute pop effect
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Scale up then down
    tween.tween_property(self, "scale", scale * 1.5, 0.1)
    tween.tween_property(self, "scale", Vector3.ZERO, 0.2)
    
    # Slight upward movement
    tween.tween_property(self, "position", position + Vector3.UP * 0.5, 0.3)
    
    # Rotate for fun effect
    tween.tween_property(self, "rotation_degrees", rotation_degrees + Vector3(0, 360, 0), 0.3)
    
    # Play hit sound
    AudioManager.play_bug_hit_sound()
    
    # Notify game manager
    GameManager.add_score(score_value)
    
    # Remove after animation
    tween.tween_callback(queue_free).set_delay(0.3)

func _on_food_reached():
    # Called when bug reaches the food
    GameManager.lose_life()
    
    # Remove this bug
    queue_free()

func _on_area_3d_body_entered(body):
    # If this bug has an Area3D child for food detection
    if body.is_in_group("food"):
        _on_food_reached()
    elif body.is_in_group("player"):
        # Optional: damage player if bug touches them
        pass