extends Control

@onready var score_label = $VBoxContainer/ScoreLabel
@onready var wave_label = $VBoxContainer/WaveLabel

func _ready():
    # Get final score from game manager
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager:
        score_label.text = "Final Score: " + str(game_manager.get_score())
        wave_label.text = "Wave Reached: " + str(game_manager.get_wave())

func _on_play_again_button_pressed():
    if AudioManager:
        AudioManager.play_ui_click_sound()
    
    print("Restarting game...")
    get_tree().change_scene_to_file("res://scenes/MainMinimal.tscn")

func _on_main_menu_button_pressed():
    if AudioManager:
        AudioManager.play_ui_click_sound()
    
    print("Returning to main menu...")
    get_tree().change_scene_to_file("res://scenes/SimpleMainMenu.tscn")

func _on_quit_button_pressed():
    if AudioManager:
        AudioManager.play_ui_click_sound()
    
    print("Quitting game...")
    get_tree().quit()