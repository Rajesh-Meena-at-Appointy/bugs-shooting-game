# 🎮 Bugs Shooting Game - Complete Setup Guide

## 📁 Project Structure Created
```
bugs-shooting-game/
├── scripts/
│   ├── Player.gd ✅
│   ├── Bug.gd ✅  
│   ├── BugSpawner.gd ✅
│   ├── GameManager.gd ✅
│   ├── TouchControls.gd ✅
│   ├── HUD.gd ✅
│   └── AudioManager.gd ✅
├── scenes/
│   ├── Main.tscn.template ✅
│   └── Bug.tscn.template ✅
├── assets/
│   ├── audio/
│   └── materials/
└── project.godot (manually create)
```

## 🔧 Step-by-Step Godot Setup

### 1. Create New Godot 4 Project
1. Open Godot 4
2. Create new project in this folder
3. Set project name: "Bugs Shooting Game"

### 2. Set Project Settings
**Project → Project Settings:**
- **Display → Window:**
  - Size: 1280x720
  - Mode: Windowed
  - Stretch Mode: canvas_items
- **Input Map:** Add these actions:
  - `move_left` (A key, Left arrow)
  - `move_right` (D key, Right arrow)  
  - `move_forward` (W key, Up arrow)
  - `move_back` (S key, Down arrow)
  - `shoot` (Left mouse, Space key)

### 3. Set Layer Names
**Project → Project Settings → Layer Names → 3D Physics:**
- Layer 1: "World"
- Layer 2: "Bugs" 
- Layer 3: "Player"
- Layer 4: "Food"

### 4. Configure Autoloads
**Project → Project Settings → Autoload:**
- Add `GameManager`: `res://scripts/GameManager.gd`
- Add `AudioManager`: `res://scripts/AudioManager.gd`

## 🏗️ Scene Creation Guide

### Create Main.tscn (Main Scene)

**Root Structure:**
```
Main (Node3D)
├── World (Node3D)
│   ├── Ground (StaticBody3D)
│   │   ├── MeshInstance3D
│   │   │   └── Mesh: QuadMesh (Size: 20x20)
│   │   │   └── Material: Green StandardMaterial3D
│   │   └── CollisionShape3D
│   │       └── Shape: BoxShape3D (Size: 20, 0.1, 20)
│   └── Food (Area3D) [Add to group: "food"]
│       ├── MeshInstance3D  
│       │   └── Mesh: SphereMesh (Bright Orange/Yellow)
│       └── CollisionShape3D
│           └── Shape: SphereShape3D
├── Player (CharacterBody3D) [Add to group: "player"]
│   ├── MeshInstance3D
│   │   └── Mesh: CapsuleMesh (Blue material)
│   ├── CollisionShape3D
│   │   └── Shape: CapsuleShape3D
│   └── CameraPivot (Node3D)
│       └── Camera3D
│           └── Position: (0, 0, 0.3)
├── BugSpawner (Node3D) [Add to group: "bug_spawner"]
│   └── SpawnPoints (Node3D)
│       ├── SpawnPoint1 (Node3D) Position: (-8, 1, -8)
│       ├── SpawnPoint2 (Node3D) Position: (8, 1, -8)  
│       ├── SpawnPoint3 (Node3D) Position: (-8, 1, 8)
│       └── SpawnPoint4 (Node3D) Position: (8, 1, 8)
├── GameManager (Node)
├── UI (CanvasLayer)
│   ├── TouchControls (Control)
│   │   ├── MovementJoystick (Control)
│   │   │   ├── Background (TextureRect)
│   │   │   └── Knob (TextureRect)
│   │   ├── CameraArea (Control)
│   │   └── FireButton (Button)
│   │       └── Text: "🔫 FIRE"
│   └── HUD (Control)
│       ├── ScoreLabel (Label)
│       ├── LivesLabel (Label)
│       ├── WaveLabel (Label)
│       ├── GameOverPanel (Panel)
│       │   ├── GameOverLabel (Label)
│       │   ├── FinalScoreLabel (Label)
│       │   └── RestartButton (Button)
│       └── PausePanel (Panel)
│           ├── ResumeButton (Button)
│           └── MainMenuButton (Button)
└── AudioManager (Node)
    ├── BGMusic (AudioStreamPlayer)
    ├── ShootSound (AudioStreamPlayer)
    ├── BugHitSound (AudioStreamPlayer)
    └── GameOverSound (AudioStreamPlayer)
```

**Script Attachments:**
- Player → `res://scripts/Player.gd`
- BugSpawner → `res://scripts/BugSpawner.gd`  
- GameManager → `res://scripts/GameManager.gd`
- TouchControls → `res://scripts/TouchControls.gd`
- HUD → `res://scripts/HUD.gd`
- AudioManager → `res://scripts/AudioManager.gd`

### Create Bug.tscn Scene

**Bug Structure:**
```
Bug (CharacterBody3D)
├── MeshInstance3D
│   └── Mesh: SphereMesh (Radius: 0.3)
│   └── Material: Bright colored StandardMaterial3D
├── CollisionShape3D
│   └── Shape: SphereShape3D (Radius: 0.3)
└── FoodDetector (Area3D)
    └── CollisionShape3D
        └── Shape: SphereShape3D (Radius: 0.5)
```

**Settings:**
- Collision Layer: 2 (Bugs)
- Collision Mask: 1 (World)
- Add to group: "bugs"
- Attach script: `res://scripts/Bug.gd`

## 📱 Android Export Setup

### 1. Install Android Build Template
- **Project → Install Android Build Template**

### 2. Export Settings  
**Project → Export:**
- Add Android export preset
- **Options:**
  - Package: Unique name (com.yourname.bugsshootinggame)
  - Screen: Landscape
  - Permissions: None needed
- **Architecture:** arm64-v8a (recommended)

### 3. Test on Device
- Enable USB debugging on Android device
- Build and deploy: **Project → Export → Android (Runnable)**

## 🎨 Materials & Assets

### Create Materials
1. **Ground Material:** Green StandardMaterial3D
2. **Bug Materials:** Bright colors (Red, Blue, Yellow, Green)
3. **Player Material:** Blue StandardMaterial3D  
4. **Food Material:** Bright orange/yellow with emission

### Audio Files (Optional)
- Place in `assets/audio/`:
  - Background music (cheerful, kid-friendly)
  - Shoot sound (pop/toy gun sound)
  - Bug hit sound (cute pop/ding)
  - Game over sound

## 🎮 Controls

### Desktop:
- **WASD:** Movement
- **Mouse:** Look around
- **Left Click/Space:** Shoot
- **ESC:** Pause/Resume

### Mobile:
- **Left Joystick:** Movement
- **Right Touch Area:** Camera look
- **Fire Button:** Shoot

## 🚀 Testing

1. **Desktop Test:** Run project (F5)
2. **Mobile Test:** Export to Android device
3. **Verify:** Movement, shooting, bug spawning, scoring

## 🔧 Troubleshooting

**Common Issues:**
- **No movement:** Check InputMap actions
- **No shooting:** Verify collision layers
- **UI not visible:** Check CanvasLayer settings
- **Audio not playing:** Check AudioManager autoload

**Mobile Issues:**
- **Touch not working:** Verify TouchControls script attachment
- **Performance:** Reduce max_bugs in BugSpawner
- **Export fails:** Check Android SDK setup

## 🎯 Game Features

✅ **Working Features:**
- 3D movement and camera control
- Touch controls for mobile
- Bug AI that moves toward food
- Raycast shooting system
- Score and lives system
- Wave progression
- Game over/restart
- Audio system ready

**Ready to Play!** 🎮

Launch Godot → Open Project → Run (F5) → Enjoy!