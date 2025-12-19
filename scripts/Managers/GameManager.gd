extends Node

# Game state
enum GameState { MENU, PLAYING, PAUSED, GAME_OVER }
var current_state = GameState.MENU

# Score system
var score: int = 0
var high_score: int = 0
var lives: int = 3
var max_lives: int = 3

# Wave system
var current_wave: int = 1

# Signals for UI and other systems
signal score_changed(new_score: int)
signal lives_changed(new_lives: int)
signal game_over
signal game_started
signal wave_completed(wave_number: int)

# References
var player: Node3D
var ui_manager: Node
var bug_spawner: Node3D

# Game settings
@export var starting_lives: int = 3
@export var life_bonus_score: int = 100  # Bonus points every X score

func _ready():
    # Set as singleton/autoload if not already
    if not get_tree().has_meta("GameManager"):
        get_tree().set_meta("GameManager", self)
    
    # Load high score
    load_high_score()
    
    # Initialize game
    reset_game()

func _input(event):
    # Handle pause
    if event.is_action_pressed("ui_cancel") and current_state == GameState.PLAYING:
        pause_game()
    elif event.is_action_pressed("ui_cancel") and current_state == GameState.PAUSED:
        resume_game()

# Game state management
func start_game():
    print("Game Started!")
    current_state = GameState.PLAYING
    reset_game()
    game_started.emit()

func pause_game():
    if current_state != GameState.PLAYING:
        return
    
    current_state = GameState.PAUSED
    get_tree().paused = true
    
    # Show pause menu
    if ui_manager and ui_manager.has_method("show_pause_menu"):
        ui_manager.show_pause_menu()

func resume_game():
    if current_state != GameState.PAUSED:
        return
    
    current_state = GameState.PLAYING
    get_tree().paused = false
    
    # Hide pause menu
    if ui_manager and ui_manager.has_method("hide_pause_menu"):
        ui_manager.hide_pause_menu()

func end_game():
    current_state = GameState.GAME_OVER
    
    # Update high score
    if score > high_score:
        high_score = score
        save_high_score()
    
    # Stop all game systems
    if bug_spawner and bug_spawner.has_method("stop_spawning"):
        bug_spawner.stop_spawning()
    
    print("Game Over! Final Score: ", score)
    game_over.emit()

func reset_game():
    score = 0
    lives = starting_lives
    current_wave = 1
    
    # Update UI
    score_changed.emit(score)
    lives_changed.emit(lives)
    
    # Get references if not already set
    if not player:
        player = get_tree().get_first_node_in_group("player")
    if not ui_manager:
        ui_manager = get_tree().get_first_node_in_group("ui")
    if not bug_spawner:
        bug_spawner = get_tree().get_first_node_in_group("bug_spawner")

# Score system
func add_score(points: int):
    score += points
    
    # Check for life bonus
    var old_life_bonus_tier = (score - points) / life_bonus_score
    var new_life_bonus_tier = score / life_bonus_score
    
    if new_life_bonus_tier > old_life_bonus_tier:
        add_life()
    
    score_changed.emit(score)
    print("Score: ", score)

func get_score() -> int:
    return score

func get_high_score() -> int:
    return high_score

# Lives system
func lose_life():
    lives -= 1
    lives_changed.emit(lives)
    
    print("Life lost! Remaining: ", lives)
    
    if lives <= 0:
        end_game()

func add_life():
    if lives < max_lives:
        lives += 1
        lives_changed.emit(lives)
        print("Life gained! Total: ", lives)

func get_lives() -> int:
    return lives

# Wave system
func next_wave():
    current_wave += 1
    wave_completed.emit(current_wave - 1)
    print("Wave completed! Starting wave: ", current_wave)

func get_current_wave() -> int:
    return current_wave

# Data persistence
func save_high_score():
    var config = ConfigFile.new()
    config.set_value("game", "high_score", high_score)
    config.save("user://savegame.cfg")

func load_high_score():
    var config = ConfigFile.new()
    var err = config.load("user://savegame.cfg")
    
    if err == OK:
        high_score = config.get_value("game", "high_score", 0)
    else:
        high_score = 0

# Utility functions
func get_game_stats() -> Dictionary:
    return {
        "score": score,
        "high_score": high_score,
        "lives": lives,
        "wave": current_wave,
        "state": GameState.keys()[current_state]
    }

func is_game_active() -> bool:
    return current_state == GameState.PLAYING

func restart_game():
    end_game()
    await get_tree().create_timer(0.5).timeout
    start_game()

# Static access function for other scripts
static func instance() -> Node:
    var tree = Engine.get_main_loop() as SceneTree
    if tree:
        return tree.get_meta("GameManager", null)
    return null