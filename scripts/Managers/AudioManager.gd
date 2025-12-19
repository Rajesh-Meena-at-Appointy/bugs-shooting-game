extends Node

# Audio players
@onready var bg_music = $BGMusic
@onready var shoot_sound = $ShootSound
@onready var bug_hit_sound = $BugHitSound
@onready var game_over_sound = $GameOverSound

# Volume settings
@export var master_volume: float = 1.0
@export var music_volume: float = 0.7
@export var sfx_volume: float = 0.8

func _ready():
    # Set up as autoload singleton
    if not get_tree().has_meta("AudioManager"):
        get_tree().set_meta("AudioManager", self)
    
    # Start background music
    if bg_music:
        bg_music.volume_db = linear_to_db(music_volume * master_volume)
        bg_music.play()

func play_shoot_sound():
    if shoot_sound:
        shoot_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        # Create a simple beep sound
        create_beep_sound(shoot_sound, 800, 0.1)

func play_bug_hit_sound():
    if bug_hit_sound:
        bug_hit_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        # Create a hit sound
        create_beep_sound(bug_hit_sound, 400, 0.2)

func play_game_over_sound():
    if game_over_sound:
        game_over_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        game_over_sound.play()

func stop_music():
    if bg_music:
        bg_music.stop()

func set_master_volume(volume: float):
    master_volume = clamp(volume, 0.0, 1.0)
    update_volumes()

func set_music_volume(volume: float):
    music_volume = clamp(volume, 0.0, 1.0)
    if bg_music:
        bg_music.volume_db = linear_to_db(music_volume * master_volume)

func set_sfx_volume(volume: float):
    sfx_volume = clamp(volume, 0.0, 1.0)

# Create simple beep sounds
func create_beep_sound(player: AudioStreamPlayer, frequency: float, duration: float):
    var generator = AudioStreamGenerator.new()
    generator.mix_rate = 22050.0
    generator.buffer_length = duration
    
    player.stream = generator
    player.play()
    
    # Stop after duration
    var timer = Timer.new()
    timer.wait_time = duration
    timer.one_shot = true
    timer.timeout.connect(func(): player.stop())
    add_child(timer)
    timer.start()

func update_volumes():
    set_music_volume(music_volume)
    # SFX volumes are updated when played