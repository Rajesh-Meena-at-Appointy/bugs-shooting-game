extends Area3D

enum PowerUpType {
    HEALTH,
    RAPID_FIRE,
    DOUBLE_DAMAGE,
    SHIELD
}

@export var power_up_type: PowerUpType = PowerUpType.HEALTH
@export var lifetime: float = 15.0
var collected = false

func _ready():
    # Set up area detection
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)
    
    # Auto-destroy after lifetime
    var timer = Timer.new()
    timer.wait_time = lifetime
    timer.one_shot = true
    timer.timeout.connect(queue_free)
    add_child(timer)
    timer.start()
    
    # Floating animation
    var float_tween = create_tween()
    float_tween.set_loops()
    float_tween.tween_property(self, "position:y", position.y + 0.5, 1.0)
    float_tween.tween_property(self, "position:y", position.y - 0.5, 1.0)
    
    # Rotation animation
    var rotate_tween = create_tween()
    rotate_tween.set_loops()
    rotate_tween.tween_property(self, "rotation_degrees:y", 360, 2.0)

func _on_body_entered(body):
    if collected:
        return
        
    if body.is_in_group("player"):
        collect_power_up(body)

func collect_power_up(player):
    collected = true
    
    # Apply power-up effect
    match power_up_type:
        PowerUpType.HEALTH:
            heal_player(player)
        PowerUpType.RAPID_FIRE:
            rapid_fire_effect(player)
        PowerUpType.DOUBLE_DAMAGE:
            double_damage_effect(player)
        PowerUpType.SHIELD:
            shield_effect(player)
    
    # Visual effect
    create_collect_effect()
    
    # Sound
    if AudioManager:
        AudioManager.play_celebration_sound()
    
    # Remove power-up
    queue_free()

func heal_player(player):
    # Heal player if they have health system
    if player.has_node("PlayerHealth"):
        var health_system = player.get_node("PlayerHealth")
        health_system.heal(25)
    print("Health power-up collected!")

func rapid_fire_effect(player):
    print("Rapid fire power-up collected!")
    # This could be implemented with a temporary fire rate boost

func double_damage_effect(player):
    print("Double damage power-up collected!")
    # This could be implemented with a damage multiplier

func shield_effect(player):
    print("Shield power-up collected!")
    # This could be implemented with temporary invulnerability

func create_collect_effect():
    # Create a simple visual effect
    var effect_material = StandardMaterial3D.new()
    effect_material.albedo_color = Color.YELLOW
    effect_material.emission_enabled = true
    effect_material.emission = Color.GOLD
    
    modulate = Color.YELLOW
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector3.ZERO, 0.3)
    tween.tween_property(self, "modulate:a", 0.0, 0.3)