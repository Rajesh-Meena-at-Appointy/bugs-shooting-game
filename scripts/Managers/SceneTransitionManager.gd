extends Node

# Scene Transition Manager for smooth scene changes
# Handles loading screens, transitions, and scene management

signal scene_loading_started(scene_path: String)
signal scene_loading_progress(progress: float)
signal scene_loading_finished(scene_path: String)
signal transition_started
signal transition_finished

# Transition types
enum TransitionType {
    FADE,
    SLIDE_LEFT,
    SLIDE_RIGHT,
    SLIDE_UP,
    SLIDE_DOWN,
    ZOOM_IN,
    ZOOM_OUT,
    CIRCULAR_WIPE
}

# Current state
var is_transitioning: bool = false
var current_scene_path: String = ""
var game_timer: float = 0.0

# Transition overlay
var transition_overlay: Control
var loading_screen: Control
var progress_bar: ProgressBar
var loading_label: Label

# Settings
@export var transition_duration: float = 0.5
@export var default_transition: TransitionType = TransitionType.FADE

func _ready():
    # Set as singleton
    if not get_tree().has_meta("SceneTransitionManager"):
        get_tree().set_meta("SceneTransitionManager", self)
    
    # Create transition overlay
    create_transition_overlay()
    
    # Store current scene path
    current_scene_path = get_tree().current_scene.scene_file_path

func _process(delta):
    game_timer += delta

func create_transition_overlay():
    # Create overlay for transitions
    transition_overlay = ColorRect.new()
    transition_overlay.name = "TransitionOverlay"
    transition_overlay.color = Color.BLACK
    transition_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    
    # Add to scene tree at highest layer
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 100  # High layer to be on top
    canvas_layer.add_child(transition_overlay)
    add_child(canvas_layer)
    
    # Initially transparent
    transition_overlay.modulate.a = 0.0
    
    # Create loading screen
    create_loading_screen()

func create_loading_screen():
    loading_screen = Control.new()
    loading_screen.name = "LoadingScreen"
    loading_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    loading_screen.visible = false
    
    # Background
    var bg = ColorRect.new()
    bg.color = Color(0.1, 0.1, 0.2, 1.0)  # Dark blue
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    loading_screen.add_child(bg)
    
    # Loading text
    loading_label = Label.new()
    loading_label.text = "Loading..."
    loading_label.add_theme_font_size_override("font_size", 32)
    loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    loading_screen.add_child(loading_label)
    
    # Progress bar
    progress_bar = ProgressBar.new()
    progress_bar.size = Vector2(400, 20)
    progress_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
    progress_bar.position.y += 60
    progress_bar.position.x -= 200
    loading_screen.add_child(progress_bar)
    
    # Add loading screen to overlay
    transition_overlay.add_child(loading_screen)

# Main transition function
func change_scene(scene_path: String, transition_type: TransitionType = default_transition):
    if is_transitioning:
        print("Already transitioning, ignoring request")
        return false
    
    if not ResourceLoader.exists(scene_path):
        print("Scene not found: ", scene_path)
        return false
    
    is_transitioning = true
    transition_started.emit()
    
    # Start transition
    await start_transition_out(transition_type)
    
    # Load new scene
    await load_scene_async(scene_path)
    
    # End transition
    await start_transition_in(transition_type)
    
    is_transitioning = false
    transition_finished.emit()
    
    return true

# Quick scene change without loading screen
func change_scene_immediate(scene_path: String, transition_type: TransitionType = default_transition):
    if is_transitioning:
        return false
    
    if not ResourceLoader.exists(scene_path):
        print("Scene not found: ", scene_path)
        return false
    
    is_transitioning = true
    transition_started.emit()
    
    # Start transition out
    await start_transition_out(transition_type)
    
    # Change scene immediately
    get_tree().change_scene_to_file(scene_path)
    current_scene_path = scene_path
    
    # Transition in
    await start_transition_in(transition_type)
    
    is_transitioning = false
    transition_finished.emit()
    
    return true

# Async scene loading with progress
func load_scene_async(scene_path: String):
    scene_loading_started.emit(scene_path)
    
    # Show loading screen
    loading_screen.visible = true
    update_loading_text("Loading...")
    
    # Start loading
    var loader = ResourceLoader.load_threaded_request(scene_path)
    if loader != OK:
        print("Failed to start loading: ", scene_path)
        loading_screen.visible = false
        return
    
    # Wait for loading with progress updates
    var progress = 0.0
    while true:
        var status = ResourceLoader.load_threaded_get_status(scene_path)
        
        match status:
            ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
                print("Invalid resource: ", scene_path)
                loading_screen.visible = false
                return
            
            ResourceLoader.THREAD_LOAD_IN_PROGRESS:
                # Update progress
                var progress_array = []
                ResourceLoader.load_threaded_get_status(scene_path, progress_array)
                if progress_array.size() > 0:
                    progress = progress_array[0]
                    update_loading_progress(progress)
                
                await get_tree().process_frame
            
            ResourceLoader.THREAD_LOAD_LOADED:
                # Loading complete
                progress = 1.0
                update_loading_progress(progress)
                break
            
            ResourceLoader.THREAD_LOAD_FAILED:
                print("Failed to load: ", scene_path)
                loading_screen.visible = false
                return
    
    # Get loaded scene
    var new_scene = ResourceLoader.load_threaded_get(scene_path)
    if new_scene:
        get_tree().change_scene_to_packed(new_scene)
        current_scene_path = scene_path
        scene_loading_finished.emit(scene_path)
    
    # Hide loading screen
    loading_screen.visible = false

func update_loading_progress(progress: float):
    if progress_bar:
        progress_bar.value = progress * 100
    
    var percentage = int(progress * 100)
    update_loading_text("Loading... %d%%" % percentage)
    
    scene_loading_progress.emit(progress)

func update_loading_text(text: String):
    if loading_label:
        loading_label.text = text
        
        # Animate loading dots
        var dots = ""
        var dot_count = int(game_timer) % 4
        for i in dot_count:
            dots += "."
        
        loading_label.text = text.replace("...", dots)

# Transition effects
func start_transition_out(transition_type: TransitionType):
    match transition_type:
        TransitionType.FADE:
            await fade_out()
        TransitionType.SLIDE_LEFT:
            await slide_out(Vector2(-get_viewport().size.x, 0))
        TransitionType.SLIDE_RIGHT:
            await slide_out(Vector2(get_viewport().size.x, 0))
        TransitionType.SLIDE_UP:
            await slide_out(Vector2(0, -get_viewport().size.y))
        TransitionType.SLIDE_DOWN:
            await slide_out(Vector2(0, get_viewport().size.y))
        TransitionType.ZOOM_IN:
            await zoom_out(2.0)
        TransitionType.ZOOM_OUT:
            await zoom_out(0.0)
        TransitionType.CIRCULAR_WIPE:
            await circular_wipe_out()

func start_transition_in(transition_type: TransitionType):
    match transition_type:
        TransitionType.FADE:
            await fade_in()
        TransitionType.SLIDE_LEFT, TransitionType.SLIDE_RIGHT, TransitionType.SLIDE_UP, TransitionType.SLIDE_DOWN:
            await slide_in()
        TransitionType.ZOOM_IN, TransitionType.ZOOM_OUT:
            await zoom_in()
        TransitionType.CIRCULAR_WIPE:
            await circular_wipe_in()

# Fade effects
func fade_out():
    var tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 1.0, transition_duration)
    await tween.finished

func fade_in():
    var tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)
    await tween.finished

# Slide effects
func slide_out(offset: Vector2):
    transition_overlay.modulate.a = 1.0
    var current_scene = get_tree().current_scene
    
    var tween = create_tween()
    tween.tween_property(current_scene, "position", offset, transition_duration)
    await tween.finished

func slide_in():
    var current_scene = get_tree().current_scene
    current_scene.position = Vector2.ZERO
    
    var tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)
    await tween.finished

# Zoom effects
func zoom_out(scale_factor: float):
    transition_overlay.modulate.a = 1.0
    var current_scene = get_tree().current_scene
    
    var tween = create_tween()
    tween.tween_property(current_scene, "scale", Vector2.ONE * scale_factor, transition_duration)
    await tween.finished

func zoom_in():
    var current_scene = get_tree().current_scene
    current_scene.scale = Vector2.ONE
    
    var tween = create_tween()
    tween.tween_property(transition_overlay, "modulate:a", 0.0, transition_duration)
    await tween.finished

# Circular wipe effect
func circular_wipe_out():
    # Implement circular wipe using shader (advanced)
    # For now, use fade as fallback
    await fade_out()

func circular_wipe_in():
    await fade_in()

# Utility functions
func is_scene_loading() -> bool:
    return loading_screen.visible if loading_screen else false

func get_current_scene_path() -> String:
    return current_scene_path

func reload_current_scene():
    if current_scene_path != "":
        change_scene_immediate(current_scene_path)

func restart_game():
    change_scene_immediate("res://scenes/Main.tscn")

func go_to_main_menu():
    change_scene("res://scenes/MainMenu.tscn", TransitionType.FADE)

# Static access
static func instance() -> Node:
    var tree = Engine.get_main_loop() as SceneTree
    if tree:
        return tree.get_meta("SceneTransitionManager", null)
    return null