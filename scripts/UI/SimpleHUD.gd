extends CanvasLayer

# UI elements
@onready var score_label = $UI/TopLeft/ScoreLabel
@onready var wave_label = $UI/TopLeft/WaveLabel
@onready var lives_label = $UI/TopLeft/LivesLabel
@onready var health_bar = $UI/TopRight/HealthBar
@onready var health_label = $UI/TopRight/HealthLabel

func _ready():
    # Connect to game manager signals
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager:
        game_manager.score_changed.connect(_on_score_changed)
        game_manager.wave_changed.connect(_on_wave_changed)
    
    # Update initial display
    update_display()

func update_display():
    var game_manager = get_tree().get_first_node_in_group("game_manager")
    if game_manager:
        _on_score_changed(game_manager.get_score())
        _on_wave_changed(game_manager.get_wave())
        _on_lives_changed(game_manager.get_lives())

func _on_score_changed(new_score: int):
    if score_label:
        score_label.text = "Score: " + str(new_score)
        
        # Score pop animation
        var tween = create_tween()
        score_label.scale = Vector2.ONE
        tween.tween_property(score_label, "scale", Vector2.ONE * 1.2, 0.1)
        tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)

func _on_wave_changed(new_wave: int):
    if wave_label:
        wave_label.text = "Wave: " + str(new_wave)
        
        # Wave flash animation
        var tween = create_tween()
        wave_label.modulate = Color.WHITE
        tween.tween_property(wave_label, "modulate", Color.YELLOW, 0.2)
        tween.tween_property(wave_label, "modulate", Color.WHITE, 0.2)

func _on_lives_changed(new_lives: int):
    if lives_label:
        lives_label.text = "Lives: " + str(new_lives)

func _on_health_changed(current_health: int, max_health: int):
    if health_bar:
        health_bar.value = (float(current_health) / float(max_health)) * 100.0
        
        # Color coding
        var health_percent = float(current_health) / float(max_health)
        if health_percent > 0.6:
            health_bar.modulate = Color.GREEN
        elif health_percent > 0.3:
            health_bar.modulate = Color.YELLOW
        else:
            health_bar.modulate = Color.RED
    
    if health_label:
        health_label.text = "Health: " + str(current_health)