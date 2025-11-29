# UI Manager Implementation Guide & Continuation Prompt

## Overview

This guide directs you to implement the UI Manager / Navigation feature by following the tasks outlined in the documentation in sequential order.

**Branch**: `ui-manager` (new workstream)
**Status**: 🚧 Phase 5 complete – UI input handler implemented; context-based routing (gamepad + keyboard) now operational

---

## 🎯 CURRENT STATUS: Phase 5 Complete – UI Input Handler Implemented

- PRD: `docs/ui manager/ui-manager-prd.md` – feature definition, goals, non‑goals.
- Plan: `docs/ui manager/ui-manager-plan.md` – milestones and phases.
- Tasks: `docs/ui manager/ui-manager-tasks.md` – checklist (25/43 tasks complete; Phase 5 done).
- Data Model: `docs/ui manager/general/data-model.md` – navigation + registry schema, overlay semantics, input/action model.
- Flows & Input: `docs/ui manager/general/flows-and-input.md` – key flows, canonical ui_* actions, and context-based routing matrix.
- Input foundations: `project.godot` now defines `ui_accept/ui_cancel/ui_pause/ui_{up,down,left,right}` with keyboard + gamepad + stick bindings; `U_ButtonPromptRegistry` maps ui_* prompts; `DEV_PITFALLS` documents pause reservation and mobile emulation flag.
- Navigation state implemented:
  - Navigation slice resource + `.tres`
  - Reducer + selectors + action creators registered with ActionRegistry
  - Navigation slice registered in `M_StateStore` as transient (skips persistence/StateHandoff)
- UI registry implemented:
  - `RS_UIScreenDefinition` resource with validation against `U_SceneRegistry`
  - `U_UIRegistry` loader/lookup helpers (close modes, parent validation)
  - Registry entries added under `resources/ui_screens/` for base scenes + pause/settings/input overlays
- Scene Manager now reconciles navigation slice state:
  - `M_SceneManager` subscribes to navigation slice updates, computes deltas, and keeps base scene/overlay stacks in sync with declared state
  - Overlay push/pop behavior respects `CloseMode` (resume gameplay vs return stack) with 0.15s fade tweens
  - Legacy public APIs (`transition_to_scene`, `push_overlay`, etc.) remain intact for existing callers while the new state-driven path runs in parallel
- Phase 4a complete (panels + controllers):
  - BaseMenuScreen/BaseOverlay/BasePanel live under `scripts/ui/base/` with shared store wiring, focus management, and `_on_back_pressed()` hooks backed by `tests/unit/ui/test_base_ui_classes.gd`.
  - Main menu, pause menu, endgame screens, and all settings/input overlays now extend the base classes, bind to registry metadata, and dispatch `U_NavigationActions` instead of touching `M_SceneManager` directly; coverage added in `tests/unit/ui/test_main_menu.gd`, `tests/unit/ui/test_endgame_screens.gd`, and the updated overlay/unit suites.
  - HUD pause state, MobileControls visibility, and the virtual pause button now rely on `U_NavigationSelectors` (see `tests/unit/ui/test_hud_controller.gd`, `tests/unit/ui/test_mobile_controls.gd`, `tests/unit/ui/test_virtual_button.gd`).
- Phase 4b complete (pause/input consolidation - T070–T075):
  - **S_PauseSystem** (T070): Refactored to watch navigation slice instead of reading raw input; derives pause state from `U_NavigationSelectors.is_paused()`, applies `get_tree().paused`, coordinates cursor state via `M_CursorManager`.
  - **M_CursorManager** (T071): Removed `_unhandled_input()` pause handling; now reacts only to explicit calls from S_PauseSystem or Scene Manager.
  - **M_SceneManager** (T072): Removed entire `_input()` ESC/pause handler and pause-blocking variables; added transition guard to `_reconcile_overlay_stack()` to defer overlay changes during base scene transitions.
  - **Integration tests** (T074): Updated 3 tests (`test_pause_system.gd`, `test_edge_cases.gd`, `test_input_during_transition.gd`) to use navigation actions instead of calling removed `_input()` method; all scene manager integration tests pass (89/89).
  - **Documentation** (T075): Added comprehensive "UI Manager / Input Manager Boundary" section to `DEV_PITFALLS.md` covering responsibilities, flow examples, common mistakes, and testing patterns.
- Phase 5 complete (UI Input Handler - T053–T055):
  - **Documentation** (T053): Added section 2 to `flows-and-input.md` with canonical ui_* action table (keyboard + gamepad + stick mappings), ESC/Start behavior matrix by context (gameplay/main_menu/endgame shells), and focus navigation patterns.
  - **UIInputHandler** (T054): Created `scripts/ui/ui_input_handler.gd` running in PROCESS_MODE_ALWAYS, listening to `_unhandled_input()` for ui_cancel/ui_pause (identical behavior), and dispatching navigation actions based on context matrix from flows-and-input.md; integrated into `scenes/root.tscn` under Managers group.
  - **Tests** (T055): Created `tests/unit/ui/test_ui_input_handler.gd` with 10 scenarios covering gameplay (no overlays → OPEN_PAUSE, pause overlay → CLOSE_TOP_OVERLAY, settings return overlay, gamepad settings resume overlay), main menu (settings panel → return to main, root panel → no-op), endgame (game_over → RETRY, victory → SKIP_TO_CREDITS, credits → SKIP_TO_MENU), and ui_pause/ui_cancel equivalence; all tests pass (92/92 in full UI suite).
- Tests: All UI tests pass (92/92); input routing now flows through UIInputHandler → navigation actions → reconciliation.
- Phase 6 status: ✅ T060 complete – ran `godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/unit -ginclude_subdirs -gexit` (121 scripts / 800 tests / 796 passing / 4 expected pending tween tests) to record the hardening baseline.
- Next: Phase 6 tasks (T061–T063) – manual QA verification of all UI flows, document cross-links, and remove obsolete SceneManager APIs once navigation owns all callers.

---

## Instructions  **YOU MUST DO THIS - NON-NEGOTIABLE**

### 1. Review Project Foundations

- `AGENTS.md` – Project conventions and patterns.
- `docs/general/DEV_PITFALLS.md` – Common mistakes to avoid.
- `docs/general/STYLE_GUIDE.md` – Code style and naming requirements.
- Scene Manager docs:
  - `docs/scene manager/scene-manager-prd.md`
  - `docs/scene manager/scene-manager-plan.md`
  - `docs/scene manager/scene-manager-tasks.md`
- State Store docs:
  - `docs/state store/redux-state-store-prd.md`
  - `docs/state store/redux-state-store-implementation-plan.md`
  - `docs/state store/redux-state-store-tasks.md`
- Input Manager docs:
  - `docs/input manager/input-manager-prd.md`
  - `docs/input manager/input-manager-plan.md`
  - `docs/input manager/input-manager-tasks.md`

### 2. Review UI Manager Documentation

- `docs/ui manager/ui-manager-prd.md` – Full UI Manager specification.
- `docs/ui manager/ui-manager-plan.md` – Implementation plan with phase breakdown.
- `docs/ui manager/ui-manager-tasks.md` – Task list and phases.
- `docs/ui manager/general/data-model.md` – Navigation and UI registry data model.
- `docs/ui manager/general/flows-and-input.md` – Flow narratives and input routing matrix.

### 3. Understand Existing Architecture

- `scripts/managers/m_scene_manager.gd` – Scene transitions, overlays, pause.
- `scripts/state/m_state_store.gd` – Redux store and slice registration.
- `scripts/state/reducers/u_scene_reducer.gd` – Scene slice reducer.
- `scripts/state/reducers/u_menu_reducer.gd` – Menu slice reducer.
- `scripts/managers/m_input_device_manager.gd` – Device detection and signals.
- `scripts/ui/*` – Current UI controllers and overlays (main menu, pause, settings, endgame, input).

### 4. Execute UI Manager Tasks in Order

Work through the tasks in `ui-manager-tasks.md` sequentially:

1. **Phase 0** (T001–T003): Architecture & Data Model
2. **Phase 1** (T010–T014): Navigation State & Selectors
3. **Phase 2** (T020–T024): UI Registry & Screen Definitions
4. **Phase 3** (T030–T033): Scene Manager Integration (Reactive Mode)
5. **Phase 4** (T040–T045): UI Panels & Controller Refactors
6. **Phase 5** (T050–T052): UI Input Handler (Gamepad & Keyboard)
7. **Phase 6** (T060–T063): Hardening & Regression Guardrails

### 5. Follow TDD Discipline

For each task:

1. Write the test first (unit or integration).
2. Run the test and verify it fails for the expected reason.
3. Implement the minimal code to make it pass.
4. Run the test suite and verify it passes.
5. Commit with a clear, focused message.

### 6. Preserve Compatibility (“Everything Still Works”)

You MUST:

- Keep existing Scene Manager, State Store, Input Manager, HUD, and MobileControls flows working at all times.
- Avoid breaking external APIs (`M_SceneManager.transition_to_scene`, `push_overlay`, etc.) during migration.
- Update tests and docs only when behavior changes are intentional and explicitly approved.
- Use selectors and navigation state as the **only** place new UI logic reads “where are we in the UI?”.

---

## Critical Notes

- **No Autoloads**: UI Manager must follow the existing pattern (root scene + in‑scene managers). Navigation reducers live in the state store; Scene Manager remains scene‑tree based.
- **State-First Architecture**: Navigation and UI state are declarative. Reducers + registry define behavior; managers enforce it.
- **Immutable State**: Follow existing Redux patterns (`.duplicate(true)`, pure reducers).
- **Input Contracts**: UI controllers must rely on `ui_*` actions, not hardcoded keycodes or gamepad buttons. Input Manager remains responsible for mapping hardware to `ui_*`.

---

## Future Status Updates

Update this continuation prompt when:

- Phase 1 is complete and navigation reducers/selectors are implemented.
- Phase 2 has a working UI registry with entries for all existing UI screens/overlays.
- Phase 3 has Scene Manager reconciliation integrated and tested.
- Phases 4–6 progressively migrate UI controllers and input routing.

For each phase, summarize:

- What changed.
- Which tests were added/updated.
- Any known issues/deferred items.
