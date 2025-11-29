@icon("res://resources/editor_icons/system.svg")
extends BaseECSSystem
class_name S_PauseSystem

## Pause System - Manages engine-level pause state from navigation slice
##
## T070: Refactored to derive pause state from navigation slice instead of direct input.
## Responsibilities:
## - Subscribe to navigation slice updates
## - Apply engine-level pause (get_tree().paused) based on U_NavigationSelectors.is_paused()
## - Emit pause_state_changed signal for other systems
## - Coordinate cursor state with M_CursorManager
##
## Does NOT handle input directly - pause/unpause flows through navigation actions.

signal pause_state_changed(is_paused: bool)

const U_NavigationSelectors := preload("res://scripts/state/selectors/u_navigation_selectors.gd")

var _store: M_StateStore = null
var _cursor_manager: M_CursorManager = null
var _is_paused: bool = false

func _ready() -> void:
	super._ready()

	# Wait for tree to be fully ready (M_StateStore needs to add itself to group)
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

	# Subscribe to navigation slice updates (T070: derive pause from navigation state)
	_store.slice_updated.connect(_on_slice_updated)

	# Read initial pause state from navigation slice
	var full_state: Dictionary = _store.get_state()
	var nav_state: Dictionary = full_state.get("navigation", {})
	_is_paused = U_NavigationSelectors.is_paused(nav_state)
	_apply_pause_to_engine(_is_paused)

func _exit_tree() -> void:
	# Clean up subscriptions
	if _store and _store.slice_updated.is_connected(_on_slice_updated):
		_store.slice_updated.disconnect(_on_slice_updated)

## Handle state store slice updates (T070: watch navigation slice, not gameplay)
func _on_slice_updated(slice_name: StringName, slice_state: Dictionary) -> void:
	if slice_name != StringName("navigation"):
		return

	var new_paused: bool = U_NavigationSelectors.is_paused(slice_state)

	# Only emit if state changed
	if new_paused != _is_paused:
		_is_paused = new_paused
		_apply_pause_to_engine(_is_paused)
		pause_state_changed.emit(_is_paused)

## Apply pause state to engine and cursor (T070: centralize pause application)
func _apply_pause_to_engine(paused: bool) -> void:
	get_tree().paused = paused

	# Coordinate cursor state with pause
	if _cursor_manager:
		if paused:
			# Paused: show cursor for UI interaction
			_cursor_manager.set_cursor_state(false, true)
		else:
			# Unpaused: hide cursor for gameplay
			_cursor_manager.set_cursor_state(true, false)

## Check if game is currently paused (for other systems)
func is_paused() -> bool:
	return _is_paused
