extends Node

# ShootingController - Dedicated shooting system
class_name ShootingController

@export var fire_rate: float = 5.0  # Shots per second
@export var range: float = 50.0
@export var damage: int = 1
@export var auto_fire: bool = false

# Shooting state
var can_shoot: bool = true
var shots_fired: int = 0
var shots_hit: int = 0
var last_shot_time: float = 0.0
var game_timer: float = 0.0

# References
@onready var camera = get_parent().get_node("CameraPivot/Camera3D")

# Signals
signal shot_fired(from_position: Vector3, direction: Vector3)
signal target_hit(target: Node, hit_point: Vector3)
signal shot_missed(end_point: Vector3)

func _ready():
	# Connect to save manager for accuracy tracking
	if SaveLoadManager:
		shot_fired.connect(_on_shot_fired)
		target_hit.connect(_on_target_hit)

func _process(delta):
	game_timer += delta

func _input(event):
	# Handle shooting input
	if event.is_action_pressed("shoot"):
		if auto_fire:
			start_auto_fire()
		else:
			fire_shot()
	
	if event.is_action_released("shoot") and auto_fire:
		stop_auto_fire()

func fire_shot() -> bool:
	if not can_shoot:
		return false
	
	# Check fire rate
	var current_time = game_timer
	var time_since_last_shot = current_time - last_shot_time
	var min_interval = 1.0 / fire_rate
	
	if time_since_last_shot < min_interval:
		return false
	
	last_shot_time = current_time
	can_shoot = false
	
	# Perform raycast
	var hit_result = perform_raycast()
	
	# Emit signals
	shot_fired.emit(get_shoot_origin(), get_shoot_direction())
	
	# Handle hit result
	if hit_result:
		handle_hit(hit_result)
	else:
		handle_miss()
	
	# Reset shooting after brief cooldown
	var cooldown_timer = get_tree().create_timer(min_interval)
	cooldown_timer.timeout.connect(func(): can_shoot = true)
	
	return true

func perform_raycast() -> Dictionary:
	if not camera:
		return {}
	
	var space_state = get_viewport().get_world_3d().direct_space_state
	var from = get_shoot_origin()
	var to = from + get_shoot_direction() * range
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 2  # Bug layer
	query.exclude = [get_parent()]  # Don't hit player
	
	var result = space_state.intersect_ray(query)
	return result

func get_shoot_origin() -> Vector3:
	if camera:
		return camera.global_position
	return get_parent().global_position

func get_shoot_direction() -> Vector3:
	if camera:
		return -camera.global_transform.basis.z
	return Vector3.FORWARD

func handle_hit(hit_result: Dictionary):
	var hit_object = hit_result.get("collider")
	var hit_point = hit_result.get("position", Vector3.ZERO)
	
	if hit_object and hit_object.has_method("hit"):
		# Apply damage
		hit_object.hit()
		shots_hit += 1
		
		# Emit hit signal
		target_hit.emit(hit_object, hit_point)
		
		# Create hit effect
		create_hit_effect(hit_point)
		
		# Play hit sound
		AudioManager.play_bug_hit_sound()
	else:
		handle_miss()

func handle_miss():
	var miss_point = get_shoot_origin() + get_shoot_direction() * range
	shot_missed.emit(miss_point)
	
	# Create miss effect (optional)
	create_miss_effect(miss_point)

func create_hit_effect(position: Vector3):
	# Create particle effect at hit point
	var hit_particles = preload("res://effects/HitEffect.tscn")
	if hit_particles:
		var effect = hit_particles.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = position

func create_miss_effect(position: Vector3):
	# Optional miss effect (dust, sparks, etc.)
	pass

# Auto fire system
var auto_fire_timer: Timer

func start_auto_fire():
	if auto_fire_timer:
		auto_fire_timer.queue_free()
	
	auto_fire_timer = Timer.new()
	auto_fire_timer.wait_time = 1.0 / fire_rate
	auto_fire_timer.autostart = true
	auto_fire_timer.timeout.connect(fire_shot)
	add_child(auto_fire_timer)

func stop_auto_fire():
	if auto_fire_timer:
		auto_fire_timer.queue_free()
		auto_fire_timer = null

# Mobile shooting interface
func mobile_shoot():
	fire_shot()

# Weapon upgrades
func upgrade_fire_rate(increase: float):
	fire_rate += increase

func upgrade_damage(increase: int):
	damage += increase

func upgrade_range(increase: float):
	range += increase

# Statistics
func get_accuracy() -> float:
	if shots_fired > 0:
		return float(shots_hit) / float(shots_fired) * 100.0
	return 0.0

func get_shots_fired() -> int:
	return shots_fired

func get_shots_hit() -> int:
	return shots_hit

func reset_statistics():
	shots_fired = 0
	shots_hit = 0

# Signal handlers for save manager
func _on_shot_fired(from_pos: Vector3, direction: Vector3):
	shots_fired += 1
	if SaveLoadManager:
		SaveLoadManager.add_shot_fired()

func _on_target_hit(target: Node, hit_point: Vector3):
	if SaveLoadManager:
		SaveLoadManager.add_shot_hit()
		SaveLoadManager.add_bug_killed()
