extends CharacterBody3D

const SPEED = 1.5  # Slower but tougher
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var player_position = Vector3.ZERO
var health = 3  # Takes multiple hits
var charge_timer = 0.0
var charge_cooldown = 3.0
var is_charging = false

func _ready():
    add_to_group("bugs")

func _physics_process(delta):
    charge_timer += delta
    
    # Add gravity
    if not is_on_floor():
        velocity.y -= gravity * delta
    
    # Find player
    var player = get_tree().get_first_node_in_group("player")
    if player:
        player_position = player.global_position
        
        var direction = (player_position - global_position).normalized()
        
        # Charge attack every few seconds
        if charge_timer >= charge_cooldown and not is_charging:
            start_charge()
        
        var speed = SPEED
        if is_charging:
            speed = SPEED * 3.0  # Charge speed
            
            # Stop charge after 1 second
            if charge_timer >= charge_cooldown + 1.0:
                is_charging = false
                charge_timer = 0.0
        
        velocity.x = direction.x * speed
        velocity.z = direction.z * speed
    
    move_and_slide()

func start_charge():
    is_charging = true
    modulate = Color.RED  # Visual indicator
    print("Tank Bug charging!")

func hit():
    health -= 1
    print("Tank Bug hit! Health: ", health)
    
    # Flash red when hit but not killed
    var tween = create_tween()
    modulate = Color.RED
    tween.tween_property(self, "modulate", Color.DARK_RED, 0.1)
    tween.tween_property(self, "modulate", Color.WHITE, 0.1)
    
    if health <= 0:
        die()

func die():
    print("Tank Bug destroyed!")
    
    # Notify game manager
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager:
        game_manager.bug_killed()
    
    # Play hit sound
    if AudioManager:
        AudioManager.play_bug_hit_sound()
    
    # Create bigger hit effect
    var hit_effect = preload("res://effects/HitEffect.tscn").instantiate()
    get_tree().current_scene.add_child(hit_effect)
    hit_effect.global_position = global_position
    hit_effect.scale = Vector3.ONE * 2.0  # Bigger explosion
    
    queue_free()