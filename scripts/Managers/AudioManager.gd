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

func play_ui_click_sound():
    # Create a UI click sound using the shoot sound player
    if shoot_sound:
        shoot_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        # Create a short click sound
        create_beep_sound(shoot_sound, 600, 0.05)

func play_game_over_sound():
    if game_over_sound:
        game_over_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(game_over_sound, 200, 1.0)

func play_player_hurt_sound():
    if get_node_or_null("PlayerHurtSound"):
        var player = $PlayerHurtSound
        player.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(player, 300, 0.3)

func play_player_death_sound():
    if get_node_or_null("PlayerDeathSound"):
        var player = $PlayerDeathSound
        player.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(player, 150, 2.0)

func play_tank_charge_sound():
    if bug_hit_sound:
        bug_hit_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(bug_hit_sound, 100, 0.5)

func play_deflect_sound():
    if shoot_sound:
        shoot_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(shoot_sound, 900, 0.1)

func play_celebration_sound():
    if bg_music:
        bg_music.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(bg_music, 1000, 0.5)

func play_sneaky_vanish_sound():
    if bug_hit_sound:
        bug_hit_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(bug_hit_sound, 500, 0.2)

func play_sneaky_appear_sound():
    if bug_hit_sound:
        bug_hit_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(bug_hit_sound, 700, 0.2)

func play_decoy_hit_sound():
    if shoot_sound:
        shoot_sound.volume_db = linear_to_db(sfx_volume * master_volume)
        create_beep_sound(shoot_sound, 450, 0.1)

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