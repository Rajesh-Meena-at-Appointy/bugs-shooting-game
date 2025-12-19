extends Node

# Player Health System
@export var max_health: int = 100
@export var current_health: int = 100
@export var invulnerability_time: float = 2.0
@export var health_regen_rate: float = 5.0  # Health per second
@export var regen_delay: float = 5.0  # Delay before regen starts

# State
var is_invulnerable: bool = false
var last_damage_time: float = 0.0
var damage_timer: float = 0.0
var is_alive: bool = true

# References
@onready var player = get_parent()
var health_bar: ProgressBar
var damage_overlay: ColorRect

# Signals
signal health_changed(current: int, max: int)
signal player_damaged(damage: int)
signal player_died
signal health_regenerated(amount: int)

func _ready():
    current_health = max_health
    
    # Find UI elements
    health_bar = get_tree().get_first_node_in_group("health_bar")
    damage_overlay = get_tree().get_first_node_in_group("damage_overlay")
    
    # Update UI
    update_health_ui()

func _process(delta):
    # Update damage timer
    damage_timer += delta
    
    # Handle invulnerability timer
    if is_invulnerable:
        if damage_timer - last_damage_time >= invulnerability_time:
            is_invulnerable = false
    
    # Handle health regeneration
    handle_health_regen(delta)

func handle_health_regen(delta):
    if not is_alive or current_health >= max_health:
        return
    
    var time_since_damage = damage_timer - last_damage_time
    
    # Start regen after delay
    if time_since_damage >= regen_delay:
        var regen_amount = health_regen_rate * delta
        heal(regen_amount)

func take_damage(damage: int, source: Node = null):
    if not is_alive or is_invulnerable or damage <= 0:
        return false
    
    # Apply damage
    current_health = max(0, current_health - damage)
    last_damage_time = damage_timer
    
    # Set invulnerability
    is_invulnerable = true
    
    # Visual effects
    show_damage_effect()
    
    # Audio feedback
    AudioManager.play_player_hurt_sound()
    
    # Camera shake
    shake_camera(damage)
    
    # Emit signals
    player_damaged.emit(damage)
    health_changed.emit(current_health, max_health)
    
    print("Player took ", damage, " damage. Health: ", current_health, "/", max_health)
    
    # Check death
    if current_health <= 0:
        die()
        return true
    
    update_health_ui()
    return true

func heal(amount: float):
    if not is_alive or current_health >= max_health:
        return
    
    var old_health = current_health
    current_health = min(max_health, current_health + int(amount))
    
    var healed_amount = current_health - old_health
    if healed_amount > 0:
        health_regenerated.emit(healed_amount)
        health_changed.emit(current_health, max_health)
        update_health_ui()

func die():
    if not is_alive:
        return
    
    is_alive = false
    current_health = 0
    
    # Visual effects
    show_death_effect()
    
    # Audio
    AudioManager.play_player_death_sound()
    
    # Camera shake
    shake_camera(50)
    
    # Game over
    player_died.emit()
    GameManager.end_game()
    
    print("Player died!")

func revive():
    is_alive = true
    current_health = max_health
    is_invulnerable = false
    
    update_health_ui()
    health_changed.emit(current_health, max_health)

func show_damage_effect():
    if not damage_overlay:
        return
    
    # Red flash effect
    damage_overlay.color = Color.RED * 0.3
    damage_overlay.visible = true
    
    var tween = create_tween()
    tween.tween_property(damage_overlay, "color:a", 0.0, 0.5)
    tween.tween_callback(func(): damage_overlay.visible = false)

func show_death_effect():
    if not damage_overlay:
        return
    
    # Dark red death effect
    damage_overlay.color = Color.DARK_RED * 0.7
    damage_overlay.visible = true
    
    var tween = create_tween()
    tween.tween_property(damage_overlay, "color:a", 0.8, 1.0)

func shake_camera(intensity: float):
    if not player or not player.has_method("shake_camera"):
        return
    
    player.shake_camera(intensity * 0.01)

func update_health_ui():
    if health_bar:
        health_bar.value = (float(current_health) / float(max_health)) * 100
        
        # Color coding
        var health_percent = float(current_health) / float(max_health)
        if health_percent > 0.6:
            health_bar.modulate = Color.GREEN
        elif health_percent > 0.3:
            health_bar.modulate = Color.YELLOW
        else:
            health_bar.modulate = Color.RED

# Public getters
func get_health() -> int:
    return current_health

func get_max_health() -> int:
    return max_health

func get_health_percent() -> float:
    return float(current_health) / float(max_health)

func is_player_alive() -> bool:
    return is_alive

func is_player_invulnerable() -> bool:
    return is_invulnerable

# Setters
func set_max_health(value: int):
    max_health = value
    current_health = min(current_health, max_health)
    update_health_ui()

func add_max_health(amount: int):
    max_health += amount
    current_health += amount  # Also heal when increasing max health
    update_health_ui()