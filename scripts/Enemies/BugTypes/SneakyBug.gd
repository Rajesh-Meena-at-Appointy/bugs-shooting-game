extends "res://scripts/Bug.gd"

# SneakyBug - Invisible, teleports, creates decoys
class_name SneakyBug

# Sneaky properties
@export var invisibility_duration: float = 3.0
@export var visible_duration: float = 2.0
@export var teleport_distance: float = 5.0
@export var decoy_count: int = 2

# States
enum SneakyState { VISIBLE, INVISIBLE, TELEPORTING }
var sneaky_state = SneakyState.VISIBLE
var state_timer: float = 0.0
var decoys: Array[Node3D] = []

# Visual
var original_modulate: Color
var is_truly_invisible: bool = false

func _init():
    # Override parent properties
    speed = 2.5  # Slightly faster than normal
    health = 2   # Medium health
    score_value = 30  # High points for tricky enemy

func _ready():
    super._ready()
    
    # Store original appearance
    original_modulate = modulate
    
    # Setup sneaky visual
    setup_sneaky_visual()
    
    # Start visible
    make_visible()

func setup_sneaky_visual():
    # Purple, translucent appearance
    var sneaky_material = StandardMaterial3D.new()
    sneaky_material.albedo_color = Color.PURPLE
    sneaky_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    
    if mesh_instance:
        mesh_instance.material_overlay = sneaky_material

# Override physics process for state management
func _physics_process(delta):
    super._physics_process(delta)
    
    state_timer += delta
    handle_sneaky_behavior(delta)

func handle_sneaky_behavior(delta):
    match sneaky_state:
        SneakyState.VISIBLE:
            if state_timer >= visible_duration:
                start_invisibility()
        
        SneakyState.INVISIBLE:
            if state_timer >= invisibility_duration:
                if randf() < 0.5:  # 50% chance to teleport
                    teleport_to_random_location()
                else:
                    make_visible()
        
        SneakyState.TELEPORTING:
            # Brief state during teleportation
            pass

func start_invisibility():
    sneaky_state = SneakyState.INVISIBLE
    state_timer = 0.0
    make_invisible()
    
    # Create decoys
    spawn_decoys()
    
    AudioManager.play_sneaky_vanish_sound()

func make_invisible():
    is_truly_invisible = true
    
    # Fade out effect
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.1, 0.5)
    
    # Disable collision while invisible
    collision_layer = 0

func make_visible():
    sneaky_state = SneakyState.VISIBLE
    state_timer = 0.0
    is_truly_invisible = false
    
    # Fade in effect
    var tween = create_tween()
    tween.tween_property(self, "modulate", original_modulate, 0.5)
    
    # Re-enable collision
    collision_layer = 2  # Bug layer
    
    # Clear decoys
    clear_decoys()
    
    AudioManager.play_sneaky_appear_sound()

func teleport_to_random_location():
    sneaky_state = SneakyState.TELEPORTING
    
    # Find valid teleport location
    var new_position = find_teleport_location()
    
    # Teleport effect at old location
    create_teleport_effect(global_position)
    
    # Move to new location
    global_position = new_position
    
    # Teleport effect at new location
    create_teleport_effect(global_position)
    
    # Become visible after teleport
    await get_tree().create_timer(0.3).timeout
    make_visible()

func find_teleport_location() -> Vector3:
    var attempts = 10
    var valid_position = global_position
    
    for i in attempts:
        # Random position within teleport distance
        var angle = randf() * TAU
        var distance = randf_range(2.0, teleport_distance)
        
        var test_position = global_position + Vector3(
            cos(angle) * distance,
            0,
            sin(angle) * distance
        )
        
        # Check if position is valid (not in walls, etc.)
        if is_position_valid(test_position):
            valid_position = test_position
            break
    
    return valid_position

func is_position_valid(pos: Vector3) -> bool:
    # Simple validation - check if position is on ground
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(
        pos + Vector3.UP,
        pos + Vector3.DOWN * 2
    )
    query.collision_mask = 1  # World layer
    
    var result = space_state.intersect_ray(query)
    return result.size() > 0

func spawn_decoys():
    clear_decoys()  # Remove old decoys first
    
    for i in decoy_count:
        var decoy = create_decoy()
        decoys.append(decoy)

func create_decoy() -> Node3D:
    # Create a copy of this bug as decoy
    var decoy_scene = preload("res://scenes/SneakyBugDecoy.tscn")
    var decoy = decoy_scene.instantiate()
    
    # Position randomly around the sneaky bug
    var angle = randf() * TAU
    var distance = randf_range(2.0, 4.0)
    decoy.global_position = global_position + Vector3(
        cos(angle) * distance,
        0,
        sin(angle) * distance
    )
    
    get_tree().current_scene.add_child(decoy)
    return decoy

func clear_decoys():
    for decoy in decoys:
        if is_instance_valid(decoy):
            decoy.queue_free()
    decoys.clear()

func create_teleport_effect(pos: Vector3):
    # Purple smoke effect
    var effect = preload("res://effects/TeleportEffect.tscn").instantiate()
    get_tree().current_scene.add_child(effect)
    effect.global_position = pos

# Override hit detection
func hit():
    if is_truly_invisible:
        # Can't be hit while truly invisible
        create_miss_effect()
        return
    
    # Normal hit
    super.hit()
    
    # Clear decoys when destroyed
    clear_decoys()

func create_miss_effect():
    # Visual feedback for missed shot
    var miss_text = preload("res://ui/MissText.tscn").instantiate()
    get_tree().current_scene.add_child(miss_text)
    miss_text.global_position = global_position

# Override movement when invisible
func move_towards_target(delta):
    if is_truly_invisible:
        # Move differently when invisible (more erratic)
        add_invisible_movement(delta)
    else:
        super.move_towards_target(delta)

func add_invisible_movement(delta):
    # Slow, unpredictable movement while invisible
    var random_direction = Vector3(
        randf_range(-1, 1),
        0,
        randf_range(-1, 1)
    ).normalized()
    
    velocity.x = random_direction.x * speed * 0.5
    velocity.z = random_direction.z * speed * 0.5

# Cleanup when destroyed
func _exit_tree():
    clear_decoys()