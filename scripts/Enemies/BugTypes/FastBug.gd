extends "res://scripts/Bug.gd"

# FastBug - Quick moving, low health, erratic movement
class_name FastBug

func _init():
    # Override parent properties
    speed = 4.0  # Much faster than normal bug (2.0)
    health = 1
    score_value = 15  # More points for harder target
    
    # Fast bug specific properties
    direction_change_time = 0.3  # Changes direction frequently
    zigzag_intensity = 2.0

# Override movement for erratic behavior
func move_towards_target(delta):
    if not current_target:
        return
    
    # Add zigzag movement pattern
    add_zigzag_movement(delta)
    
    # Call parent movement
    super.move_towards_target(delta)
    
    # Add speed burst occasionally
    if randf() < 0.1:  # 10% chance per frame
        speed_burst()

var zigzag_timer = 0.0
var zigzag_direction = 1
var direction_change_time = 0.3
var zigzag_intensity = 2.0

func add_zigzag_movement(delta):
    zigzag_timer += delta
    
    # Change zigzag direction periodically
    if zigzag_timer >= direction_change_time:
        zigzag_direction *= -1
        zigzag_timer = 0.0
    
    # Add perpendicular movement to create zigzag
    if current_target:
        var forward_dir = (current_target.global_position - global_position).normalized()
        var right_dir = forward_dir.cross(Vector3.UP).normalized()
        
        velocity += right_dir * zigzag_direction * zigzag_intensity

func speed_burst():
    # Temporary speed boost
    var original_speed = speed
    speed *= 1.5
    
    # Reset speed after short time
    await get_tree().create_timer(0.5).timeout
    speed = original_speed

# Override hit for special effects
func hit():
    # Fast bug explodes with multiple small particles
    create_fast_bug_explosion()
    super.hit()

func create_fast_bug_explosion():
    # Create multiple small explosion effects
    for i in range(3):
        var particle = preload("res://effects/SmallExplosion.tscn").instantiate()
        get_tree().current_scene.add_child(particle)
        particle.global_position = global_position + Vector3(
            randf_range(-0.3, 0.3),
            randf_range(-0.3, 0.3),
            randf_range(-0.3, 0.3)
        )

# Override ready for visual setup
func _ready():
    super._ready()
    
    # Fast bug visual tweaks
    if mesh_instance and mesh_instance.mesh:
        # Smaller, more elongated
        scale = Vector3(0.7, 0.7, 0.7)
        
        # Add speed trail material
        setup_fast_bug_visual()

func setup_fast_bug_visual():
    # Create speed trail effect (optional)
    var trail_material = StandardMaterial3D.new()
    trail_material.albedo_color = Color.CYAN
    trail_material.emission = Color.CYAN * 0.3
    
    if mesh_instance:
        mesh_instance.material_overlay = trail_material