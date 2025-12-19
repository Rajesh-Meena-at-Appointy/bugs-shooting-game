extends Node

# BugAI - Advanced AI controller for all bug types
class_name BugAI

# AI States
enum AIState {
    IDLE,
    SEEKING_TARGET,
    MOVING_TO_TARGET,
    ATTACKING,
    FLEEING,
    PATROLLING,
    DEAD
}

# Target types
enum TargetType {
    FOOD,
    PLAYER,
    RANDOM_POINT
}

# AI Properties
@export var ai_update_rate: float = 0.1  # How often to update AI (performance)
@export var detection_range: float = 15.0
@export var attack_range: float = 2.0
@export var flee_health_threshold: float = 0.2  # Flee when health < 20%

# Current state
var current_state: AIState = AIState.IDLE
var target_type: TargetType = TargetType.FOOD
var current_target: Node3D = null
var last_known_target_position: Vector3

# References
@onready var bug_body = get_parent()
var food_target: Node3D
var player_target: Node3D

# AI timing
var ai_timer: float = 0.0
var state_change_timer: float = 0.0
var decision_cooldown: float = 1.0

# Pathfinding
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var patrol_radius: float = 8.0

# Behavioral modifiers
var aggression_level: float = 0.5  # 0 = passive, 1 = very aggressive
var intelligence_level: float = 0.5  # 0 = dumb, 1 = smart
var curiosity_level: float = 0.3  # 0 = focused, 1 = easily distracted

func _ready():
    # Find targets
    food_target = get_tree().get_first_node_in_group("food")
    player_target = get_tree().get_first_node_in_group("player")
    
    # Generate patrol points
    generate_patrol_points()
    
    # Start AI
    set_state(AIState.SEEKING_TARGET)

func _process(delta):
    ai_timer += delta
    state_change_timer += delta
    
    # Update AI at specified rate for performance
    if ai_timer >= ai_update_rate:
        ai_timer = 0.0
        update_ai()

func update_ai():
    # Update current state
    match current_state:
        AIState.IDLE:
            handle_idle_state()
        AIState.SEEKING_TARGET:
            handle_seeking_state()
        AIState.MOVING_TO_TARGET:
            handle_moving_state()
        AIState.ATTACKING:
            handle_attacking_state()
        AIState.FLEEING:
            handle_fleeing_state()
        AIState.PATROLLING:
            handle_patrolling_state()
        AIState.DEAD:
            return
    
    # Check for state transitions
    check_state_transitions()

func handle_idle_state():
    # Look for something to do
    if should_seek_target():
        set_state(AIState.SEEKING_TARGET)
    elif should_patrol():
        set_state(AIState.PATROLLING)

func handle_seeking_state():
    # Find the best target
    var best_target = find_best_target()
    
    if best_target:
        set_target(best_target)
        set_state(AIState.MOVING_TO_TARGET)
    else:
        # No target found, patrol or idle
        if patrol_points.size() > 0:
            set_state(AIState.PATROLLING)
        else:
            set_state(AIState.IDLE)

func handle_moving_state():
    if not current_target:
        set_state(AIState.SEEKING_TARGET)
        return
    
    var distance_to_target = bug_body.global_position.distance_to(current_target.global_position)
    
    # Check if reached target
    if distance_to_target <= attack_range:
        if target_type == TargetType.FOOD:
            # Reached food
            on_food_reached()
        elif target_type == TargetType.PLAYER and aggression_level > 0.3:
            set_state(AIState.ATTACKING)
    
    # Update last known position
    last_known_target_position = current_target.global_position
    
    # Check if target is still valid
    if not is_instance_valid(current_target):
        set_state(AIState.SEEKING_TARGET)

func handle_attacking_state():
    if not current_target:
        set_state(AIState.SEEKING_TARGET)
        return
    
    # Attack behavior (implemented by specific bug types)
    perform_attack()
    
    # Return to moving after attack
    await get_tree().create_timer(1.0).timeout
    if current_state == AIState.ATTACKING:
        set_state(AIState.MOVING_TO_TARGET)

func handle_fleeing_state():
    # Run away from threats
    var flee_direction = get_flee_direction()
    var flee_target = bug_body.global_position + flee_direction * 5.0
    
    move_towards_position(flee_target)
    
    # Stop fleeing after some time
    if state_change_timer > 3.0:
        set_state(AIState.SEEKING_TARGET)

func handle_patrolling_state():
    if patrol_points.is_empty():
        set_state(AIState.SEEKING_TARGET)
        return
    
    var patrol_target = patrol_points[current_patrol_index]
    var distance = bug_body.global_position.distance_to(patrol_target)
    
    if distance <= 2.0:
        # Reached patrol point, move to next
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
    
    move_towards_position(patrol_target)
    
    # Check if should abandon patrol for better target
    if intelligence_level > 0.5 and should_abandon_patrol():
        set_state(AIState.SEEKING_TARGET)

func find_best_target() -> Node3D:
    var best_target: Node3D = null
    var best_score: float = -1.0
    
    # Score food target
    if food_target:
        var food_score = calculate_target_score(food_target, TargetType.FOOD)
        if food_score > best_score:
            best_score = food_score
            best_target = food_target
            target_type = TargetType.FOOD
    
    # Score player target if aggressive enough
    if player_target and aggression_level > 0.3:
        var player_score = calculate_target_score(player_target, TargetType.PLAYER)
        if player_score > best_score:
            best_score = player_score
            best_target = player_target
            target_type = TargetType.PLAYER
    
    return best_target

func calculate_target_score(target: Node3D, type: TargetType) -> float:
    if not target:
        return 0.0
    
    var distance = bug_body.global_position.distance_to(target.global_position)
    var score: float = 0.0
    
    # Base score by type
    match type:
        TargetType.FOOD:
            score = 1.0  # Always prefer food
        TargetType.PLAYER:
            score = 0.5 * aggression_level  # Only if aggressive
    
    # Distance modifier (closer = better)
    if distance <= detection_range:
        score *= (detection_range - distance) / detection_range
    else:
        score = 0.0  # Too far
    
    return score

func set_target(target: Node3D):
    current_target = target
    if target:
        last_known_target_position = target.global_position

func set_state(new_state: AIState):
    if new_state != current_state:
        on_state_exit(current_state)
        current_state = new_state
        state_change_timer = 0.0
        on_state_enter(new_state)

func on_state_enter(state: AIState):
    match state:
        AIState.FLEEING:
            # Increase speed when fleeing
            if bug_body.has_method("set_speed_multiplier"):
                bug_body.set_speed_multiplier(1.5)

func on_state_exit(state: AIState):
    match state:
        AIState.FLEEING:
            # Reset speed
            if bug_body.has_method("set_speed_multiplier"):
                bug_body.set_speed_multiplier(1.0)

# State transition checks
func should_seek_target() -> bool:
    return current_target == null or not is_instance_valid(current_target)

func should_patrol() -> bool:
    return patrol_points.size() > 0 and curiosity_level > 0.2

func should_flee() -> bool:
    if not bug_body.has_method("get_health_percent"):
        return false
    return bug_body.get_health_percent() < flee_health_threshold

func should_abandon_patrol() -> bool:
    return find_best_target() != null

func check_state_transitions():
    # Global state checks
    if should_flee() and current_state != AIState.FLEEING:
        set_state(AIState.FLEEING)
        return
    
    # Decision cooldown to prevent rapid state changes
    if state_change_timer < decision_cooldown:
        return
    
    # State-specific transitions handled in state methods

# Movement interface
func move_towards_position(target_pos: Vector3):
    if bug_body and bug_body.has_method("set_target_position"):
        bug_body.set_target_position(target_pos)

# Combat
func perform_attack():
    # Base attack - override in specific bug types
    if current_target and current_target.has_method("take_damage"):
        current_target.take_damage(1)

func get_flee_direction() -> Vector3:
    # Run away from threats
    var flee_dir = Vector3.ZERO
    
    if player_target:
        flee_dir += bug_body.global_position - player_target.global_position
    
    return flee_dir.normalized()

# Patrol system
func generate_patrol_points():
    var center = bug_body.global_position
    var point_count = randi_range(3, 6)
    
    for i in point_count:
        var angle = (float(i) / float(point_count)) * TAU
        var point = center + Vector3(
            cos(angle) * patrol_radius,
            0,
            sin(angle) * patrol_radius
        )
        patrol_points.append(point)

# Events
func on_food_reached():
    # Food reached, damage game/player lives
    if GameManager:
        GameManager.lose_life()
    
    # Remove this bug
    bug_body.queue_free()

func on_hit():
    # React to being shot
    if intelligence_level > 0.5:
        # Smart bugs might flee or change behavior
        if randf() < 0.3:
            set_state(AIState.FLEEING)

func on_death():
    set_state(AIState.DEAD)

# Public interface
func set_aggression(level: float):
    aggression_level = clamp(level, 0.0, 1.0)

func set_intelligence(level: float):
    intelligence_level = clamp(level, 0.0, 1.0)

func set_curiosity(level: float):
    curiosity_level = clamp(level, 0.0, 1.0)

func get_current_state() -> AIState:
    return current_state