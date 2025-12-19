extends Node3D

# Bug spawning settings
@export var bug_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_bugs: int = 10
@export var bugs_per_wave: int = 1

# Wave progression
@export var wave_difficulty_increase: float = 0.1
var current_wave: int = 1
var bugs_spawned_this_wave: int = 0
var bugs_killed_this_wave: int = 0

# Spawn points
@onready var spawn_points = $SpawnPoints
var spawn_positions: Array[Node3D] = []

# Timing
var spawn_timer: float = 0.0
var current_bugs: Array[Node3D] = []

# Game state
var is_spawning_active: bool = true

func _ready():
	# Get all spawn point positions
	for child in spawn_points.get_children():
		if child is Node3D:
			spawn_positions.append(child)
	
	if spawn_positions.is_empty():
		push_error("No spawn points found! Add Node3D children to SpawnPoints node.")
	
	# Load bug scene if not assigned
	if not bug_scene:
		bug_scene = preload("res://scenes/Bug.tscn")  # You'll need to create this
	
	# Connect to game manager signals
	if GameManager:
		GameManager.game_over.connect(_on_game_over)
		GameManager.game_started.connect(_on_game_started)

func _process(delta):
	if not is_spawning_active:
		return
	
	# Update spawn timer
	spawn_timer += delta
	
	# Clean up destroyed bugs from tracking array
	clean_up_bugs()
	
	# Check if we should spawn new bugs
	if should_spawn_bug():
		spawn_bug()
		spawn_timer = 0.0

func should_spawn_bug() -> bool:
	# Don't spawn if we've reached max bugs
	if current_bugs.size() >= max_bugs:
		return false
	
	# Check if enough time has passed
	if spawn_timer < get_current_spawn_interval():
		return false
	
	return true

func get_current_spawn_interval() -> float:
	# Decrease spawn interval based on wave (gets harder)
	var difficulty_multiplier = 1.0 - (current_wave - 1) * wave_difficulty_increase
	return spawn_interval * max(difficulty_multiplier, 0.3)  # Minimum 0.3 seconds

func spawn_bug():
	if bug_scene == null or spawn_positions.is_empty():
		return
	
	# Choose random spawn point
	var spawn_point = spawn_positions[randi() % spawn_positions.size()]
	
	# Instantiate bug
	var bug_instance = bug_scene.instantiate()
	
	# Set position with small random offset
	var spawn_pos = spawn_point.global_position
	spawn_pos.x += randf_range(-1.0, 1.0)
	spawn_pos.z += randf_range(-1.0, 1.0)
	bug_instance.global_position = spawn_pos
	
	# Scale bug speed based on wave difficulty
	if bug_instance.has_method("set_speed"):
		var new_speed = 2.0 + (current_wave - 1) * 0.3
		bug_instance.set_speed(new_speed)
	
	# Add to scene
	get_tree().current_scene.add_child(bug_instance)
	
	# Track this bug
	current_bugs.append(bug_instance)
	bugs_spawned_this_wave += 1
	
	print("Bug spawned! Wave: ", current_wave, " Total bugs: ", current_bugs.size())

func clean_up_bugs():
	# Remove null references (destroyed bugs)
	var alive_bugs: Array[Node3D] = []
	for bug in current_bugs:
		if is_instance_valid(bug) and bug != null:
			alive_bugs.append(bug)
		else:
			# Bug was destroyed
			bugs_killed_this_wave += 1
	
	current_bugs = alive_bugs
	
	# Check if wave is complete
	check_wave_completion()

func check_wave_completion():
	# If we've killed enough bugs, start next wave
	var bugs_needed_for_next_wave = current_wave * 2 + 3  # Progressive wave requirements
	
	if bugs_killed_this_wave >= bugs_needed_for_next_wave:
		start_next_wave()

func start_next_wave():
	current_wave += 1
	bugs_spawned_this_wave = 0
	bugs_killed_this_wave = 0
	
	# Clear remaining bugs for clean wave start (optional)
	# clear_all_bugs()
	
	# Notify game manager about new wave
	if GameManager:
		GameManager.next_wave()
	
	print("Wave ", current_wave, " started! Difficulty increased.")

func clear_all_bugs():
	# Emergency function to clear all bugs
	for bug in current_bugs:
		if is_instance_valid(bug):
			bug.queue_free()
	current_bugs.clear()

func stop_spawning():
	is_spawning_active = false

func start_spawning():
	is_spawning_active = true

func reset_spawner():
	# Reset for new game
	current_wave = 1
	bugs_spawned_this_wave = 0
	bugs_killed_this_wave = 0
	spawn_timer = 0.0
	clear_all_bugs()
	is_spawning_active = true

func get_spawn_stats() -> Dictionary:
	return {
		"current_wave": current_wave,
		"active_bugs": current_bugs.size(),
		"bugs_spawned": bugs_spawned_this_wave,
		"bugs_killed": bugs_killed_this_wave
	}

# Signal callbacks
func _on_game_over():
	stop_spawning()

func _on_game_started():
	reset_spawner()

func _on_bug_destroyed():
	# Called when bug is destroyed by shooting
	bugs_killed_this_wave += 1
