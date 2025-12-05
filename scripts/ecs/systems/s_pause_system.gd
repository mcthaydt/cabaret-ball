@icon("res://resources/editor_icons/system.svg")
extends BaseECSSystem
class_name S_PauseSystem

## Pause System - SOLE AUTHORITY for engine pause and cursor coordination
##
## Phase 2 (T021): Refactored to derive pause and cursor state from scene slice.
##
## Responsibilities:
## - Subscribe to scene slice updates
## - Derive pause from scene.scene_stack size (overlays = paused)
## - Apply engine-level pause (get_tree().paused)
## - Coordinate cursor state with M_CursorManager based on BOTH pause state AND scene type
## - Emit pause_state_changed signal for other systems
##
## Cursor logic:
## - If paused (overlays present): cursor visible & unlocked
## - If not paused:
##   - MENU/UI/END_GAME scenes: cursor visible & unlocked
##   - GAMEPLAY scenes: cursor hidden & locked
##
## Does NOT handle input directly - pause/unpause flows through scene overlay actions.

signal pause_state_changed(is_paused: bool)

const U_SceneRegistry := preload("res://scripts/scene_management/u_scene_registry.gd")

var _store: M_StateStore = null
var _cursor_manager: M_CursorManager = null
var _is_paused: bool = false
var _current_scene_id: StringName = StringName("")
var _current_scene_type: int = -1

func _ready() -> void:
	super._ready()

	# CRITICAL: Pause system must process even when tree is paused
	# Otherwise it can't unpause the tree or handle scene transitions
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Wait for tree to be fully ready (M_StateStore, M_SceneManager need to initialize)
	await get_tree().process_frame

	# Get reference to state store
	_store = U_StateUtils.get_store(self)

	if not _store:
		push_error("S_PauseSystem: Could not find M_StateStore")
		return

	# Get reference to cursor manager (optional - pause still works without it)
	var cursor_managers: Array[Node] = get_tree().get_nodes_in_group("cursor_manager")
	if cursor_managers.size() > 0:
		_cursor_manager = cursor_managers[0] as M_CursorManager

	# Subscribe to scene slice updates (Phase 2: derive pause and cursor from scene slice)
	_store.slice_updated.connect(_on_slice_updated)

	# Read initial state from scene slice
	var full_state: Dictionary = _store.get_state()
	var scene_state: Dictionary = full_state.get("scene", {})

	# Pause is determined by overlay stack (scene_stack) size
	var scene_stack: Array = scene_state.get("scene_stack", [])
	_is_paused = scene_stack.size() > 0

	_current_scene_id = scene_state.get("current_scene_id", StringName(""))
	_current_scene_type = _get_scene_type(_current_scene_id)

	_apply_pause_and_cursor_state()

func _exit_tree() -> void:
	# Clean up subscriptions
	if _store and _store.slice_updated.is_connected(_on_slice_updated):
		_store.slice_updated.disconnect(_on_slice_updated)

## Handle state store slice updates (Phase 2: watch scene slice for both pause and scene type)
func _on_slice_updated(slice_name: StringName, slice_state: Dictionary) -> void:
	if slice_name != StringName("scene"):
		return

	var state_changed: bool = false
	var pause_changed: bool = false

	# Check pause state (derived from scene_stack size)
	var scene_stack: Array = slice_state.get("scene_stack", [])
	var new_paused: bool = scene_stack.size() > 0
	if new_paused != _is_paused:
		_is_paused = new_paused
		state_changed = true
		pause_changed = true

	# Check scene type changes
	var new_scene_id: StringName = slice_state.get("current_scene_id", StringName(""))
	if new_scene_id != _current_scene_id:
		_current_scene_id = new_scene_id
		_current_scene_type = _get_scene_type(_current_scene_id)
		state_changed = true

	# Only apply changes if pause or scene type changed
	if state_changed:
		_apply_pause_and_cursor_state()
		# Emit signal only if pause state changed
		if pause_changed:
			pause_state_changed.emit(_is_paused)

## Apply pause state to engine and cursor (Phase 2: SOLE AUTHORITY for both)
##
## Cursor logic:
## - If paused (overlay stack not empty): cursor visible & unlocked
## - If not paused:
##   - MENU/UI/END_GAME scenes: cursor visible & unlocked
##   - GAMEPLAY scenes: cursor hidden & locked
func _apply_pause_and_cursor_state() -> void:
	# Apply pause to engine
	get_tree().paused = _is_paused

	# Coordinate cursor state based on pause AND scene type
	if _cursor_manager:
		if _is_paused:
			# Paused: show cursor for UI interaction (overlays)
			_cursor_manager.set_cursor_state(false, true)
		else:
			# Not paused: cursor depends on scene type
			match _current_scene_type:
				U_SceneRegistry.SceneType.MENU, U_SceneRegistry.SceneType.UI, U_SceneRegistry.SceneType.END_GAME:
					# UI scenes: cursor visible & unlocked
					_cursor_manager.set_cursor_state(false, true)
				U_SceneRegistry.SceneType.GAMEPLAY:
					# Gameplay scenes: cursor hidden & locked
					_cursor_manager.set_cursor_state(true, false)
				_:
					# Unknown scene type: default to locked & hidden (safe default)
					_cursor_manager.set_cursor_state(true, false)

## Get scene type from scene ID
func _get_scene_type(scene_id: StringName) -> int:
	if scene_id.is_empty():
		return -1
	var scene_data: Dictionary = U_SceneRegistry.get_scene(scene_id)
	if scene_data.is_empty():
		return -1
	return scene_data.get("scene_type", -1)

## Check if game is currently paused (for other systems)
func is_paused() -> bool:
	return _is_paused
