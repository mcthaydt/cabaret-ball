# Feature Specification: UI Navigation & Manager System

**Feature Branch**: `ui-manager`
**Created**: 2025-11-24
**Status**: Draft
**Input**: User description: "UI / Menu handling as well‑architected as the rest of the codebase (Gamepad Controllable, Modular UI, Data‑Driven, Everything still works)"

## Problem Statement

The current UI and menu handling is built on a solid Scene Manager, State Store, and Input Manager foundation, but the UI layer itself is more ad‑hoc than the rest of the architecture:

- Individual UI scenes call `M_SceneManager` directly for transitions and overlays.
- The `menu` slice exists and is tested, but real menus do not yet use it as their source of truth.
- Overlay behavior (push vs push_with_return, pop vs pop_with_return) and ESC / gamepad back semantics are encoded in multiple controllers instead of one central policy.
- Gamepad support exists at the input layer, but there is no unified, declarative model for UI routing that is as clean as the Redux + ECS patterns elsewhere.

We need a UI / Navigation architecture that:

- Treats UI location and menu flow as first‑class state with reducers and selectors.
- Uses declarative data (resources) to describe screens, overlays, and panels.
- Lets `M_SceneManager` act as a reactive enforcer of desired UI state, not the sole owner of navigation logic.
- Keeps UI panels dumb, testable views that read state and dispatch actions, supporting keyboard, mouse, and gamepad uniformly.
- Preserves all existing behaviors (main menu → gameplay → pause → endgame flows) while enabling future modular UI features.

## Goals

1. **Gamepad Controllable UI**
   - All menus, overlays, and settings flows must be fully navigable via gamepad using the existing Input Manager + device detection patterns.
   - ESC / gamepad “back” semantics must be consistent and defined centrally, not per‑scene.

2. **Modular UI**
   - Break UI into reusable panels and overlays that can be composed in different shells (main menu, pause overlay, endgame screens) without duplicating logic.
   - Allow new flows (e.g., inventory, map, quest log) to be added primarily by defining state, panels, and registry entries—not by rewriting managers.

3. **Data‑Driven Navigation**
   - Define a navigation / UI state slice that fully models UI location (base scene, overlays, menu panels).
   - Introduce a UI registry (resource‑backed) describing screens/overlays/panels, their scene paths, contexts, and close behavior.
   - Move navigation rules into reducers + registry lookups so behavior is visible and testable outside the scene tree.

4. **Compatibility: Everything Still Works**
   - Preserve existing user‑visible flows:
     - Main menu → gameplay hub → pause → settings / input flows → resume.
     - Door‑based area transitions (exterior ↔ interior).
     - Endgame flows (death → game over, victory → credits → main menu).
   - Keep current Scene Manager responsibilities intact (transition queue, async loading, camera/spawn managers, pause, HUD hiding).
   - Do not regress existing tests and acceptance criteria for Scene Manager, State Store, and Input Manager.

## Non-Goals

- Replace or radically redesign `M_SceneManager`, `M_SpawnManager`, or `M_CameraManager`.
- Introduce autoload singletons for UI; managers must remain scene‑based and discoverable via groups.
- Implement a generic in‑editor menu authoring tool; the focus is on runtime architecture, not editor UX.
- Redesign the visual look or layout of existing menus and HUD; this is primarily about flow and architecture.

## User Experience Notes

**Primary Entry Points**

- **Game Launch**
  - Player starts the game and arrives at the Main Menu.
  - Gamepad, keyboard, and mouse can all navigate the menu.
  - “Play” starts or continues a run; “Settings” opens a settings panel; “Quit” exits.

- **In‑Game Pause**
  - Player presses pause (ESC / gamepad Start) in gameplay.
  - Pause overlay appears over gameplay; gameplay freezes.
  - From pause, player can:
    - Resume gameplay.
    - Open settings, input profiles, gamepad/touchscreen settings, or rebinding.
    - Return to main menu or quit to desktop, as currently implemented.

- **Endgame**
  - On death, the game over screen appears with death count and options to retry or return to menu.
  - On victory, the victory screen appears with completion stats and options to continue, view credits, or return to menu.
  - Credits screen auto‑scrolls and returns to main menu or can be skipped via a button.

**Critical Interactions**

- **Gamepad Navigation**
  - D‑pad / left stick moves focus between buttons and controls using `ui_*` actions.
  - “Confirm” (A / Cross / Enter) activates the focused control.
  - “Back” (B / Circle / ESC) behaves consistently:
    - In gameplay: opens pause.
    - In pause: closes pause to gameplay.
    - In pause sub‑overlays tagged as “return overlays” (settings, input settings, rebinding): close to previous overlay (pause).
    - In main menu panels: navigates back within the menu, not to gameplay.

- **Device Switching**
  - When the active device switches between keyboard/mouse and gamepad, prompts and focus behavior update automatically based on `M_InputDeviceManager` and existing selectors.

- **HUD Interaction**
  - HUD remains responsive and non‑blocking during gameplay.
  - HUD hides during loading screen transitions and does not overlap with modal overlays in ways that confuse input or readability.

## Technical Considerations

### Core Architecture

The target architecture:

- A **navigation / UI state slice** that fully models:
  - Base scene (`current_scene_id`, shell).
  - Overlay stack (by logical IDs).
  - Active menu panel(s) within shells like main menu and pause.
- A **data‑driven UI registry** describing:
  - Screens, overlays, and panels (IDs, scene paths, kinds, allowed contexts, close behavior).
  - Optionally recommended focus nodes for gamepad navigation.
- `M_SceneManager` as a **reactive enforcer**:
  - Reads navigation + scene slices.
  - Ensures the scene tree (ActiveSceneContainer + UIOverlayStack) matches the desired state (transitions, overlays, loading).
  - Keeps all existing responsibilities (queueing, async loading, camera/spawn/pause integration).
- **UI panels as dumb views**:
  - Panels read slices via selectors (menu, settings, input, gameplay).
  - Panels dispatch actions (menu, settings, navigation), but never call Scene Manager directly.
- A **thin UI input handler**:
  - Listens to `ui_*` actions (keyboard + gamepad) and dispatches navigation actions based on context (navigation slice + scene type).
  - Delegates device detection to `M_InputDeviceManager` and Input Manager selectors.

### Dependencies

- **State Store**: `M_StateStore`, existing slices (`scene`, `menu`, `settings`, `input`, `gameplay`, `debug`).
- **Scene Manager**: `M_SceneManager`, `U_SceneRegistry`, Transition effects (Fade, Loading).
- **Input Manager**: `M_InputDeviceManager`, `M_InputProfileManager`, `U_InputSelectors`, `U_InputActions`, virtual controls architecture.
- **HUD**: `hud_overlay.tscn`, `hud_controller.gd`, HUD group (`hud_layers`) and loading transition HUD hide/restore behavior.

### Risks / Mitigations

- **Risk: Double source of truth for navigation**
  - Mitigation: Clearly define the navigation slice as the only logical source of truth. `M_SceneManager` is an enforcer/view that never mutates navigation fields on its own—only in response to actions.

- **Risk: Regression in existing flows**
  - Mitigation: Introduce navigation slice and registry behind feature flags or incremental wiring. Maintain existing Scene Manager APIs; add tests for both old and new flows, then gradually migrate call sites.

- **Risk: Over‑engineering the registry**
  - Mitigation: Start small: describe only existing screens/overlays, with minimal fields (id, path, kind, close_mode). Expand only when needed.

## Success Metrics

- **Functional**
  - All existing UI flows (main menu, pause, settings, input overlays, endgame) operate as before, with no regressions in manual QA.
  - Gamepad control works end‑to‑end across all menus and overlays.

- **Architectural**
  - Navigation logic lives primarily in reducers + registry, not scattered across controllers.
  - New UI flows (e.g., adding an inventory overlay) can be implemented primarily by:
    - Adding registry entries.
    - Adding/using panels.
    - Extending reducers and selectors.
    - With minimal or no changes to `M_SceneManager`.

- **Testing**
  - New unit tests for navigation reducers, selectors, and registry integration.
  - New integration tests verifying scene/overlay stacks for key flows.

## Open Questions

- Should we introduce a dedicated `navigation` slice, or extend the existing `scene` + `menu` slices with navigation fields and adopt a clear ownership model?
- How much of the current `scene.scene_stack` semantics should be preserved exactly vs refactored to be fully driven by navigation reducers?
- Do we want a separate continuation prompt and phases for “UI Manager / Navigation” similar to Scene Manager and Input Manager, or keep this as a sub‑phase of Scene Manager evolution?

