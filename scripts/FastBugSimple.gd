extends CharacterBody3D

const SPEED = 6.0  # Faster than regular bugs
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var player_position = Vector3.ZERO
var zigzag_timer = 0.0
var direction_change_time = 1.0

func _ready():
    add_to_group("bugs")

func _physics_process(delta):
    zigzag_timer += delta
    
    # Add gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Find player
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player_position = player.global_position
        
        # Zigzag movement toward player
        var direction = (player_position - global_position).normalized()
        
        # Add zigzag offset
        var zigzag_offset = Vector3(
            sin(zigzag_timer * 5.0) * 2.0,  # Side to side
            0,
            cos(zigzag_timer * 3.0) * 1.0   # Forward/back variation
        )
        
        var final_direction = (direction + zigzag_offset * 0.3).normalized()
        velocity.x = final_direction.x * SPEED
        velocity.z = final_direction.z * SPEED
    
    move_and_slide()

func hit():
    print("Fast Bug hit!")
    
    # Notify game manager
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager:
        game_manager.bug_killed()
    
    # Play hit sound
    if AudioManager:
        AudioManager.play_bug_hit_sound()
    
    # Create hit effect
    var hit_effect = preload("res://effects/HitEffect.tscn").instantiate()
    get_tree().current_scene.add_child(hit_effect)
    hit_effect.global_position = global_position
    
    # Flash effect (faster for speed bug)
    var tween = create_tween()
    modulate = Color.WHITE
    tween.tween_property(self, "modulate", Color.CYAN, 0.05)
    tween.tween_property(self, "modulate", Color.WHITE, 0.05)
    tween.tween_property(self, "modulate", Color.CYAN, 0.05)
    tween.tween_property(self, "modulate", Color.WHITE, 0.05)
    
    # Destroy after effect
    tween.tween_callback(queue_free)