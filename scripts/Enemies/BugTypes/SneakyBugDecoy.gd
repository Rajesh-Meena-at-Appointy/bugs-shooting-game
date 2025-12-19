extends Node3D

# SneakyBugDecoy - Fake target that disappears when shot
class_name SneakyBugDecoy

# Decoy properties
@export var lifetime: float = 5.0
@export var flicker_rate: float = 2.0

# Visual
@onready var mesh_instance = $MeshInstance3D
var original_modulate: Color
var is_flickering: bool = true
var game_timer: float = 0.0

func _ready():
    # Set up decoy appearance (translucent)
    modulate = Color.PURPLE * 0.7
    original_modulate = modulate
    
    # Add to bugs group so it can be targeted
    add_to_group("bugs")
    
    # Set collision for shooting
    collision_layer = 2  # Bug layer
    
    # Start flickering
    start_flicker_effect()
    
    # Auto-destroy after lifetime
    var timer = Timer.new()
    timer.wait_time = lifetime
    timer.one_shot = true
    timer.timeout.connect(self_destruct)
    add_child(timer)
    timer.start()

func _physics_process(delta):
    game_timer += delta
    
    # Simple floating movement
    position.y += sin(game_timer * 2) * 0.5 * delta
    
    # Rotate slowly
    rotation_degrees.y += 30 * delta

func start_flicker_effect():
    if not is_flickering:
        return
    
    var tween = create_tween()
    tween.set_loops()
    
    # Flicker in and out of visibility
    tween.tween_property(self, "modulate:a", 0.3, 0.5)
    tween.tween_property(self, "modulate:a", 0.8, 0.5)

func hit():
    # Decoy behavior when shot
    create_decoy_destruction_effect()
    
    # Give some points (less than real bug)
    GameManager.add_score(5)
    
    # Play special sound
    AudioManager.play_decoy_hit_sound()
    
    # Destroy decoy
    queue_free()

func create_decoy_destruction_effect():
    # Different effect than real bug
    var tween = create_tween()
    tween.set_parallel(true)
    
    # Scale down quickly
    tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
    
    # Spin rapidly
    tween.tween_property(self, "rotation_degrees", rotation_degrees + Vector3(0, 720, 0), 0.3)
    
    # Change color to indicate it was fake
    tween.tween_property(self, "modulate", Color.CYAN, 0.3)

func self_destruct():
    # Fade out naturally
    var tween = create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 1.0)
    tween.tween_callback(queue_free)

# Override the default bug collision detection
func _on_area_3d_body_entered(body):
    # Decoys don't damage the player or interact with food
    # They're purely visual distractions
    pass