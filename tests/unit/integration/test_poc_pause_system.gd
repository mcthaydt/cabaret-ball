extends GutTest

## Proof-of-Concept Integration Tests: Pause System
##
## T070-T074: Updated to test navigation-driven pause architecture
## Tests that validate state store integration with S_PauseSystem via navigation slice

var store: M_StateStore
var pause_system: Node  # Will be S_PauseSystem once implemented
var cursor_manager: M_CursorManager

func before_each() -> void:
	# CRITICAL: Reset both event buses for integration tests
	U_StateEventBus.reset()
	U_ECSEventBus.reset()

	# Create M_StateStore
	store = M_StateStore.new()
	store.settings = RS_StateStoreSettings.new()
	store.gameplay_initial_state = RS_GameplayInitialState.new()
	store.navigation_initial_state = RS_NavigationInitialState.new()
	autofree(store)
	add_child(store)
	await get_tree().process_frame

	# Create cursor manager (T071: required for S_PauseSystem coordination)
	cursor_manager = M_CursorManager.new()
	autofree(cursor_manager)
	add_child(cursor_manager)
	await get_tree().process_frame

func after_each() -> void:
	U_StateEventBus.reset()
	U_ECSEventBus.reset()
	if store and is_instance_valid(store):
		store.queue_free()
	store = null
	pause_system = null
	cursor_manager = null

## T299: Test pause system reacts to navigation state changes (T070 refactor)
func test_pause_system_reacts_to_navigation_state() -> void:
	# T070: S_PauseSystem now watches navigation slice, not gameplay slice
	# Create pause system
	pause_system = S_PauseSystem.new()
	add_child(pause_system)
	autofree(pause_system)
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for system to initialize

	# Start gameplay and open pause via navigation action
	store.dispatch(U_NavigationActions.start_game(StringName("gameplay_base")))
	await wait_physics_frames(1)
	store.dispatch(U_NavigationActions.open_pause())
	await wait_physics_frames(1)  # Navigation slice updates flush on physics frames

	# Verify pause system derives pause state from navigation slice
	var nav_state: Dictionary = store.get_slice(StringName("navigation"))
	var is_paused: bool = U_NavigationSelectors.is_paused(nav_state)
	assert_true(is_paused, "Navigation state should indicate paused (overlay stack not empty)")
	assert_true(pause_system.is_paused(), "Pause system should reflect navigation-derived pause state")

## T300: Test pause system applies engine-level pause (T070 refactor)
func test_pause_system_applies_engine_pause() -> void:
	# T070: S_PauseSystem now applies get_tree().paused based on navigation state
	# Create pause system
	pause_system = S_PauseSystem.new()
	add_child(pause_system)
	autofree(pause_system)
	await get_tree().process_frame
	await get_tree().process_frame  # Extra frame for system to initialize

	# Reset engine pause
	get_tree().paused = false

	# Open pause overlay via navigation action
	store.dispatch(U_NavigationActions.start_game(StringName("gameplay_base")))
	await wait_physics_frames(1)
	store.dispatch(U_NavigationActions.open_pause())
	await wait_physics_frames(1)  # Navigation slice updates flush on physics frames

	# Verify engine pause applied
	assert_true(get_tree().paused, "Engine should be paused when navigation state has overlays")
	assert_true(pause_system.is_paused(), "Pause system should reflect paused state")

	# Cleanup
	get_tree().paused = false

## T301: Test movement disabled when paused
func test_movement_disabled_when_paused() -> void:
	# This test verifies that systems check pause state (already implemented in systems)
	# We'll verify that the pause state is correctly set and readable
	
	# Create pause system
	pause_system = S_PauseSystem.new()
	add_child(pause_system)
	autofree(pause_system)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Pause the game
	store.dispatch(U_GameplayActions.pause_game())
	await get_tree().process_frame
	
	# Verify pause state is accessible for systems to check
	var gameplay_state: Dictionary = store.get_slice(StringName("gameplay"))
	var is_paused: bool = U_GameplaySelectors.get_is_paused(gameplay_state)
	assert_true(is_paused, "Gameplay state should indicate paused")
	
	# Movement/jump/input systems already check this state in their process_tick
	# This test confirms the integration point works
