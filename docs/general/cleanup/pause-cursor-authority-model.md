---
description: "Pause & Cursor Authority Model"
created: "2025-12-04"
version: "1.0"
status: "Phase 2 - Implementation"
---

# Pause & Cursor Authority Model

## Overview

This document defines the **single authority pattern** for pause and cursor state management in Cabaret Ball. Prior to Phase 2, both `S_PauseSystem` and `M_SceneManager` controlled pause/cursor state, leading to conflicts and inconsistent behavior.

**Phase 2 Goal**: Establish `S_PauseSystem` as the **sole authority** for both engine pause and cursor coordination.

---

## Authority Hierarchy

### Single Authority: S_PauseSystem

`S_PauseSystem` is the **only** system that:
- Writes to `get_tree().paused`
- Calls `M_CursorManager.set_cursor_state()`
- Coordinates pause and cursor state based on navigation and scene context

### Supporting Authority: M_CursorManager

`M_CursorManager` is the **only** system that:
- Writes to `Input.mouse_mode`
- Manages cursor visibility (`Input.MOUSE_MODE_VISIBLE` vs `HIDDEN` vs `CAPTURED`)

**CRITICAL**: No other system should write to these properties. All pause/cursor changes flow through S_PauseSystem → M_CursorManager.

---

## State Derivation Logic

### Pause State

`S_PauseSystem` derives pause state from the **scene slice**:

```gdscript
var scene_state: Dictionary = store.get_slice(StringName("scene"))
var scene_stack: Array = scene_state.get("scene_stack", [])
var is_paused: bool = scene_stack.size() > 0
```

**Rule**: Game is paused when ANY overlay is on the stack (pause menu, settings, etc.)

### Cursor State

`S_PauseSystem` derives cursor state from **BOTH** pause state AND scene type:

```gdscript
if is_paused:
    # Overlays present: cursor visible & unlocked
    cursor_manager.set_cursor_state(false, true)
else:
    # No overlays: cursor depends on scene type
    match scene_type:
        SceneType.MENU, SceneType.UI, SceneType.END_GAME:
            # UI scenes: cursor visible & unlocked
            cursor_manager.set_cursor_state(false, true)
        SceneType.GAMEPLAY:
            # Gameplay scenes: cursor hidden & locked
            cursor_manager.set_cursor_state(true, false)
```

**Scene Type Mapping**:
- `SceneType.MENU` → Main menu, character select, etc.
- `SceneType.UI` → Settings menu, loading screen, etc.
- `SceneType.GAMEPLAY` → gameplay_base, exterior, interior_house, etc.
- `SceneType.END_GAME` → game_over, victory, credits

**Critical Requirement**: Main menu (`SceneType.MENU`) MUST have cursor visible & unlocked.

---

## Initialization Order

`S_PauseSystem` depends on:
1. `M_StateStore` - provides scene slice updates
2. `M_SceneManager` - populates scene state (current_scene_id, scene_stack)
3. `M_CursorManager` - executes cursor state changes

**Required Node Order in root.tscn**:
```
Root
└─ Managers
    ├─ M_StateStore          (1st - state foundation)
    ├─ M_SceneManager        (2nd - populates scene state)
    ├─ M_CursorManager       (3rd - cursor execution)
    └─ S_PauseSystem         (4th - coordinates pause/cursor)
```

**Initialization Pattern**:
```gdscript
func _ready() -> void:
    super._ready()

    # CRITICAL: Wait for tree to be fully ready
    await get_tree().process_frame

    # Find dependencies via groups (guaranteed ready)
    _store = get_tree().get_first_node_in_group("state_store")
    _cursor_manager = get_tree().get_first_node_in_group("cursor_manager")

    # Subscribe to scene slice updates
    _store.slice_updated.connect(_on_slice_updated)

    # Read initial state
    var full_state: Dictionary = _store.get_state()
    var scene_state: Dictionary = full_state.get("scene", {})
    # ... derive initial pause/cursor state
```

---

## M_SceneManager Responsibilities (Post-Refactor)

After Phase 2, `M_SceneManager` retains these responsibilities:

### 1. Scene Transitions
- Load/unload scenes from ActiveSceneContainer
- Manage transition queue (instant/fade/loading)
- Dispatch scene actions to state store

### 2. Overlay Stack Management
- Push/pop overlays to UIOverlayStack
- Sync overlay stack with scene.scene_stack state
- Manage focus restoration when overlays close

### 3. Particle Pause Workaround
- Set `speed_scale` on GPU particles when pause state changes
- **WHY**: GPU particles ignore `SceneTree.paused`, need manual speed_scale adjustment
- **DOES NOT** write to `get_tree().paused` (S_PauseSystem does that)

### What M_SceneManager NO LONGER Does:
- ❌ Write to `get_tree().paused`
- ❌ Call `M_CursorManager.set_cursor_state()`
- ❌ Dispatch `U_GAMEPLAY_ACTIONS.pause_game()` / `unpause_game()`
- ❌ Implement `_update_cursor_for_scene()`

---

## Forbidden Patterns

### ❌ NEVER: Direct Pause Writes Outside S_PauseSystem
```gdscript
# WRONG - only S_PauseSystem should do this
get_tree().paused = true
```

### ❌ NEVER: Direct Cursor Writes Outside M_CursorManager
```gdscript
# WRONG - only M_CursorManager should do this
Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
```

### ❌ NEVER: Direct Cursor Manager Calls Outside S_PauseSystem
```gdscript
# WRONG - only S_PauseSystem should do this
M_CursorManager.set_cursor_state(false, true)
```

### ✅ ALLOWED: Read-Only Pause Checks
```gdscript
# OK - reading pause state is safe
if get_tree().paused:
    # Skip input handling while paused
    return
```

---

## Testing Strategy

### Unit Tests
- Verify S_PauseSystem derives pause from scene_stack correctly
- Verify S_PauseSystem derives cursor from scene type correctly
- Verify M_CursorManager translates state to Input.mouse_mode correctly

### Integration Tests
- **test_pause_system.gd**: Verify pause/unpause via overlay push/pop
- **test_particles_pause.gd**: Verify particles respect pause (speed_scale)
- **test_pause_settings_flow.gd**: Verify pause → settings → resume flow
- **test_cursor_reactive_updates.gd**: Verify cursor updates on scene transitions
- **NEW - test_main_menu_cursor.gd**: Verify main menu has visible cursor on boot

### Critical Test Pattern
```gdscript
# After dispatching scene/navigation actions
await get_tree().process_frame  # Let state store update
await get_tree().process_frame  # Let S_PauseSystem react

# Then assert pause/cursor state
assert_true(get_tree().paused)
assert_true(_cursor_manager.is_cursor_visible())
```

**WHY**: S_PauseSystem reacts to `slice_updated` signals, which are asynchronous. Tests need to wait for the reaction to complete.

---

## Migration Notes

### Grep Patterns for Violations
```bash
# Find pause writes (should only be in S_PauseSystem)
grep -r "get_tree().paused =" scripts/

# Find mouse_mode writes (should only be in M_CursorManager)
grep -r "Input.mouse_mode =" scripts/

# Find cursor manager calls (should only be in S_PauseSystem)
grep -r "M_CursorManager.set_cursor_state" scripts/
grep -r "_cursor_manager.set_cursor_state" scripts/
```

### Safe Exceptions
- **M_InputDeviceManager**: Reads `get_tree().paused` to gate input (safe)
- **M_InputProfileManager**: Reads `get_tree().paused` to gate input (safe)
- **UI Input Handler**: Reads `get_tree().paused` for process mode (safe)

---

## Summary

| **Responsibility** | **Authority** | **Forbidden Elsewhere** |
|--------------------|---------------|-------------------------|
| `get_tree().paused = X` | S_PauseSystem | ✅ ENFORCED |
| `cursor_manager.set_cursor_state()` | S_PauseSystem | ✅ ENFORCED |
| `Input.mouse_mode = X` | M_CursorManager | ✅ ENFORCED |
| Overlay push/pop | M_SceneManager | ✅ OK (drives state) |
| Scene transitions | M_SceneManager | ✅ OK (drives state) |
| Particle speed_scale | M_SceneManager | ✅ OK (GPU workaround) |
| Read `get_tree().paused` | Any system | ✅ OK (read-only) |

**Golden Rule**: State flows one direction:
1. User input → Navigation/Scene actions
2. Actions → State store updates
3. State updates → S_PauseSystem reacts
4. S_PauseSystem → Engine pause & cursor state
