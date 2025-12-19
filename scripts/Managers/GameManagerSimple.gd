extends Node

# Simple Game Manager for immediate gameplay
signal score_changed(new_score: int)
signal wave_changed(new_wave: int)
signal game_over
signal wave_completed(wave_number: int)

# Game state
var current_score: int = 0
var current_wave: int = 1
var bugs_killed_this_wave: int = 0
var bugs_needed_for_wave: int = 5
var player_lives: int = 3
var game_active: bool = true

# Score values
var bug_kill_points: int = 10
var wave_bonus_points: int = 50

func _ready():
    add_to_group("game_manager")

func add_score(points: int):
    if not game_active:
        return
        
    current_score += points
    score_changed.emit(current_score)
    print("Score: ", current_score)

func bug_killed():
    if not game_active:
        return
        
    bugs_killed_this_wave += 1
    add_score(bug_kill_points)
    
    # Check wave completion
    if bugs_killed_this_wave >= bugs_needed_for_wave:
        complete_wave()

func complete_wave():
    # Wave bonus
    add_score(wave_bonus_points)
    wave_completed.emit(current_wave)
    
    # Next wave
    current_wave += 1
    bugs_killed_this_wave = 0
    bugs_needed_for_wave += 2  # Increase difficulty
    
    wave_changed.emit(current_wave)
    print("Wave ", current_wave, " started! Need to kill ", bugs_needed_for_wave, " bugs")

func player_died():
    player_lives -= 1
    
    if player_lives <= 0:
        end_game()
    else:
        print("Lives remaining: ", player_lives)

func end_game():
    game_active = false
    game_over.emit()
    print("Game Over! Final Score: ", current_score)
    
    # Load game over scene after a short delay
    var timer = Timer.new()
    timer.wait_time = 2.0
    timer.one_shot = true
    timer.timeout.connect(func(): get_tree().change_scene_to_file("res://scenes/SimpleGameOver.tscn"))
    add_child(timer)
    timer.start()

func restart_game():
    current_score = 0
    current_wave = 1
    bugs_killed_this_wave = 0
    bugs_needed_for_wave = 5
    player_lives = 3
    game_active = true
    
    score_changed.emit(current_score)
    wave_changed.emit(current_wave)

func get_score() -> int:
    return current_score

func get_wave() -> int:
    return current_wave

func get_lives() -> int:
    return player_lives