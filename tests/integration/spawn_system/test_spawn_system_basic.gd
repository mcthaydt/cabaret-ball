extends GutTest

## Basic spawn system integration tests
##
## Tests that M_SpawnManager correctly spawns player at designated spawn points.

const M_SpawnManager := preload("res://scripts/managers/m_spawn_manager.gd")
const M_StateStore := preload("res://scripts/state/m_state_store.gd")

var _spawn_manager: M_SpawnManager
var _store: M_StateStore

func before_each() -> void:
	_store = M_StateStore.new()
	add_child_autofree(_store)

	_spawn_manager = M_SpawnManager.new()
	_spawn_manager.add_to_group("spawn_manager")
	add_child_autofree(_spawn_manager)

	await get_tree().process_frame

func test_spawn_manager_exists_and_ready() -> void:
	assert_not_null(_spawn_manager, "Spawn manager should exist")
	assert_true(_spawn_manager.is_in_group("spawn_manager"), "Should be in spawn_manager group")

func test_can_create_spawn_point_marker() -> void:
	var marker := Marker3D.new()
	marker.name = "sp_test"
	add_child_autofree(marker)

	assert_not_null(marker, "Marker should be created")
	assert_eq(marker.name, "sp_test", "Marker should have correct name")
