extends Control

@onready var instructions = $VBoxContainer/Instructions
var instructions_visible = false

func _ready():
    # Hide instructions initially
    instructions.visible = false
    
    # Title animation
    var title = $VBoxContainer/Title
    var tween = create_tween()
    tween.set_loops()
    tween.tween_property(title, "modulate", Color(1, 1, 0.5), 2.0)
    tween.tween_property(title, "modulate", Color.WHITE, 2.0)

func _on_play_button_pressed():
    print("Starting game...")
    if AudioManager:
        AudioManager.play_ui_click_sound()
    
    # Load game scene
    get_tree().change_scene_to_file("res://scenes/MainMinimal.tscn")

func _on_instructions_button_pressed():
    if AudioManager:
        AudioManager.play_ui_click_sound()
    
    # Toggle instructions
    instructions_visible = !instructions_visible
    instructions.visible = instructions_visible
    
    var button = $VBoxContainer/InstructionsButton
    if instructions_visible:
        button.text = "📋 HIDE INSTRUCTIONS"
    else:
        button.text = "📋 INSTRUCTIONS"

func _on_quit_button_pressed():
    if AudioManager:
        AudioManager.play_ui_click_sound()
    
    print("Quitting game...")
    get_tree().quit()