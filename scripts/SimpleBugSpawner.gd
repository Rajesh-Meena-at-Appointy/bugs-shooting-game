extends Node3D

# Bug scenes
var bug_scenes = [
    preload("res://scenes/SimpleBug.tscn"),
    preload("res://scenes/FastBugSimple.tscn"),
    preload("res://scenes/TankBugSimple.tscn")
]

# Spawn settings
var spawn_timer = 0.0
var spawn_interval = 2.0
var max_bugs = 8
var current_bugs: Array = []
var spawn_positions = []

func _ready():
    # Create spawn positions around the map
    spawn_positions = [
        Vector3(8, 2, 8),
        Vector3(-8, 2, 8),
        Vector3(8, 2, -8),
        Vector3(-8, 2, -8),
        Vector3(0, 2, 10),
        Vector3(0, 2, -10),
        Vector3(10, 2, 0),
        Vector3(-10, 2, 0)
    ]

func _process(delta):
    spawn_timer += delta
    
    # Clean up destroyed bugs
    clean_up_bugs()
    
    # Spawn new bugs
    if spawn_timer >= spawn_interval and current_bugs.size() < max_bugs:
        spawn_random_bug()
        spawn_timer = 0.0

func clean_up_bugs():
    var alive_bugs = []
    for bug in current_bugs:
        if is_instance_valid(bug):
            alive_bugs.append(bug)
    current_bugs = alive_bugs

func spawn_random_bug():
    # Choose random bug type based on wave
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    var current_wave = 1
    if game_manager:
        current_wave = game_manager.get_wave()
    
    # Increase variety with higher waves
    var bug_index = 0
    if current_wave >= 2:
        bug_index = randi() % 2  # Normal or Fast
    if current_wave >= 3:
        bug_index = randi() % 3  # All types
    
    # Spawn bug
    var bug_scene = bug_scenes[bug_index]
    var bug_instance = bug_scene.instantiate()
    
    # Random spawn position
    var spawn_pos = spawn_positions[randi() % spawn_positions.size()]
    bug_instance.global_position = spawn_pos
    
    # Add to scene
    get_tree().current_scene.add_child(bug_instance)
    current_bugs.append(bug_instance)
    
    print("Spawned bug type ", bug_index, " at wave ", current_wave)