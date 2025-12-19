extends "res://scripts/Bug.gd"

# TankBug - Slow, high health, deals damage to player
class_name TankBug

# Tank properties
@export var armor: int = 2
@export var charge_damage: int = 25
@export var charge_speed: float = 6.0
@export var charge_distance: float = 8.0

# States
enum TankState { NORMAL, CHARGING, STUNNED }
var tank_state = TankState.NORMAL
var charge_target: Vector3
var charge_timer: float = 0.0

func _init():
    # Override parent properties
    speed = 1.0  # Much slower than normal bug (2.0)
    health = 5   # Much more health
    score_value = 25  # High points for tough enemy

func _ready():
    super._ready()
    
    # Tank visual setup
    setup_tank_visual()
    
    # Larger scale
    scale = Vector3(1.5, 1.5, 1.5)

func setup_tank_visual():
    # Dark, armored appearance
    var tank_material = StandardMaterial3D.new()
    tank_material.albedo_color = Color.DARK_RED
    tank_material.metallic = 0.8
    tank_material.roughness = 0.2
    
    if mesh_instance:
        mesh_instance.material_overlay = tank_material

# Override movement for tank behavior
func move_towards_target(delta):
    match tank_state:
        TankState.NORMAL:
            handle_normal_movement(delta)
        TankState.CHARGING:
            handle_charge_movement(delta)
        TankState.STUNNED:
            handle_stunned_state(delta)

func handle_normal_movement(delta):
    # Check if player is close for charge attack
    var player = get_tree().get_first_node_in_group("player")
    if player:
        var distance_to_player = global_position.distance_to(player.global_position)
        
        # Initiate charge if player is within range
        if distance_to_player <= charge_distance and randf() < 0.02:  # 2% chance per frame
            start_charge_attack(player.global_position)
            return
    
    # Normal movement (slower)
    super.move_towards_target(delta)

func start_charge_attack(target_pos: Vector3):
    tank_state = TankState.CHARGING
    charge_target = target_pos
    charge_timer = 0.0
    
    # Visual effect for charge
    create_charge_effect()
    
    # Audio warning
    AudioManager.play_tank_charge_sound()

func handle_charge_movement(delta):
    charge_timer += delta
    
    # Move towards charge target at high speed
    var direction = (charge_target - global_position).normalized()
    direction.y = 0  # Keep on ground
    
    velocity.x = direction.x * charge_speed
    velocity.z = direction.z * charge_speed
    
    # Check if reached target or timeout
    var distance_to_target = global_position.distance_to(charge_target)
    if distance_to_target < 1.0 or charge_timer > 2.0:
        end_charge_attack()

func end_charge_attack():
    tank_state = TankState.STUNNED
    charge_timer = 0.0
    
    # Brief stun period
    await get_tree().create_timer(1.0).timeout
    tank_state = TankState.NORMAL

func handle_stunned_state(delta):
    # Don't move during stun
    velocity.x = 0
    velocity.z = 0
    
    # Apply gravity only
    if not is_on_floor():
        velocity.y += get_gravity().y * delta

func create_charge_effect():
    # Red glow effect during charge
    if mesh_instance:
        var tween = create_tween()
        tween.set_loops()
        tween.tween_property(mesh_instance, "modulate", Color.RED, 0.2)
        tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.2)

# Override hit to handle armor
func hit():
    if tank_state == TankState.CHARGING:
        # Harder to hit while charging
        if randf() < 0.3:  # 70% chance to deflect
            create_deflect_effect()
            return
    
    # Reduce damage due to armor
    health -= max(1, 1 - armor)  # Minimum 1 damage
    
    if health <= 0:
        super.hit()
    else:
        # Show hit but not destroyed
        create_armor_hit_effect()

func create_deflect_effect():
    # Visual feedback for deflected shot
    var spark_effect = preload("res://effects/SparkEffect.tscn").instantiate()
    get_tree().current_scene.add_child(spark_effect)
    spark_effect.global_position = global_position
    
    AudioManager.play_deflect_sound()

func create_armor_hit_effect():
    # Show that tank was hit but not destroyed
    var tween = create_tween()
    tween.tween_property(self, "modulate", Color.YELLOW, 0.1)
    tween.tween_property(self, "modulate", Color.WHITE, 0.1)

# Handle collision with player
func _on_area_3d_body_entered(body):
    super._on_area_3d_body_entered(body)
    
    if body.is_in_group("player") and tank_state == TankState.CHARGING:
        # Deal damage to player during charge
        if body.has_node("PlayerHealth"):
            body.get_node("PlayerHealth").take_damage(charge_damage, self)
        
        # Stop charge after hitting player
        end_charge_attack()