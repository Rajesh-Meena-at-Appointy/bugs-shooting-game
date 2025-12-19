# 🔧 **Game Not Playing - Troubleshooting Guide**

## 🚨 **Common Issues & Solutions**

### **Issue 1: Main Scene Not Set**
```
Problem: F5 asks to select scene or shows error
Solution:
1. Project → Project Settings → Application → Run
2. Main Scene: res://scenes/Main.tscn
3. Click "Set as Main Scene" in FileSystem dock
```

### **Issue 2: Script Errors Preventing Launch**
```
Check Godot Console for errors like:
- "Script not found"
- "Parse Error"
- "Cannot load script"
```

### **Issue 3: Autoload Issues**
```
Check: Project → Project Settings → Autoload
Should have:
✅ GameManager
✅ AudioManager  
✅ SaveLoadManager
✅ SceneTransitionManager
✅ ObjectPool
```

### **Issue 4: Missing Dependencies**
```
Common missing references:
- Script paths incorrect
- Scene inheritance broken
- Resource paths wrong
```

---

## 🛠️ **Step-by-Step Debug Process**

### **Step 1: Check Project Import**
```
1. Close Godot completely
2. Delete .godot folder (if exists)
3. Reopen Godot
4. Import project fresh
```

### **Step 2: Validate Main Scene**
```
1. Double-click Main.tscn in FileSystem
2. Check if opens without errors
3. Look for red error icons on nodes
4. Verify all scripts are attached
```

### **Step 3: Check Script Paths**
```
Player node should have:
✅ Player.gd
✅ PlayerMovement.gd
✅ TouchLookController.gd
✅ ShootingController.gd
✅ PlayerHealth.gd
```

### **Step 4: Test Individual Components**
```
1. Remove all child scripts from Player
2. Try running with just Player.gd
3. Add scripts back one by one
```

---

## 🚀 **Quick Fix Solutions**

### **Solution A: Create Minimal Test Scene**
```
1. Scene → New Scene → 3D Scene
2. Add CharacterBody3D
3. Add MeshInstance3D (CapsuleMesh)
4. Add CollisionShape3D (CapsuleShape3D)
5. Save as TestScene.tscn
6. Set as Main Scene
7. Test F5
```

### **Solution B: Check Godot Version**
```
Ensure using Godot 4.2 or newer:
- Help → About → Version should be 4.x
- If 3.x, scenes won't work
```

### **Solution C: Script Error Fix**
```
If scripts have errors:
1. Open each script in scripts/ folders
2. Check for red error markers
3. Fix syntax errors
4. Save all scripts
```

---

## 🔍 **Detailed Error Checking**

### **Check 1: Console Output**
```
When pressing F5, check bottom panel:
- Output tab: Shows loading progress
- Debugger tab: Shows script errors
- Look for red error messages
```

### **Check 2: Scene Structure**
```
Main.tscn should have:
Main (Node3D)
├── World
├── Player (with scripts)
├── BugSpawner
├── UI
└── AudioManager
```

### **Check 3: File Paths**
```
All scripts should be found at:
res://scripts/Player/Player.gd
res://scripts/Enemies/Bug.gd
etc.
```

---

## 🎯 **What You Should See When Working**

### **Successful Launch Indicators:**
1. **F5 pressed** → Game window opens immediately
2. **3D scene visible** → Blue capsule on green ground
3. **Camera works** → Mouse moves camera view
4. **Movement works** → WASD moves player
5. **UI visible** → Score/health displays

### **Console Should Show:**
```
Loading main scene...
Scene loaded successfully
Game started
No error messages
```

---

## 🚨 **Emergency Backup Plan**

### **If Nothing Works - Manual Setup:**
```
1. Create new Godot 4 project
2. Copy scripts/ folder to new project
3. Create scenes manually in editor:
   - Add Node3D (rename to Main)
   - Add CharacterBody3D (rename to Player)
   - Add scripts to Player
   - Add basic 3D world (ground, lighting)
4. Test step by step
```

---

## 📞 **Help Questions to Answer:**

**Please check and tell me:**

1. **What exactly happens when you press F5?**
   - Does scene selector appear?
   - Does error message show?
   - Does game window open but black screen?
   - Does nothing happen?

2. **Check Godot Console** (bottom panel):
   - Any red error messages?
   - What does Output tab say?

3. **Check Project Settings:**
   - Is Main Scene set to res://scenes/Main.tscn?
   - Are autoloads showing correctly?

4. **Check FileSystem:**
   - Are all .gd files showing properly?
   - Any red icons on files?

**Tell me exactly what you see, and I'll fix it! 🛠️**