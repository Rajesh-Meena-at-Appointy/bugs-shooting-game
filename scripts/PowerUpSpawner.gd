extends Node3D

var power_up_scene = preload("res://scenes/HealthPowerUp.tscn")
var spawn_timer = 0.0
var spawn_interval = 20.0  # Spawn every 20 seconds
var max_power_ups = 2
var current_power_ups: Array = []

func _process(delta):
    spawn_timer += delta
    
    # Clean up collected power-ups
    clean_up_power_ups()
    
    # Spawn new power-up
    if spawn_timer >= spawn_interval and current_power_ups.size() < max_power_ups:
        spawn_power_up()
        spawn_timer = 0.0

func clean_up_power_ups():
    var active_power_ups = []
    for power_up in current_power_ups:
        if is_instance_valid(power_up):
            active_power_ups.append(power_up)
    current_power_ups = active_power_ups

func spawn_power_up():
    var power_up = power_up_scene.instantiate()
    
    # Random position on the map
    var spawn_pos = Vector3(
        randf_range(-8, 8),
        3,
        randf_range(-8, 8)
    )
    power_up.global_position = spawn_pos
    
    get_tree().current_scene.add_child(power_up)
    current_power_ups.append(power_up)
    
    print("Power-up spawned at: ", spawn_pos)