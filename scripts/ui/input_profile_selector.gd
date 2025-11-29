@icon("res://resources/editor_icons/utility.svg")
extends "res://scripts/ui/base/base_overlay.gd"
class_name InputProfileSelector

const U_InputSelectors := preload("res://scripts/state/selectors/u_input_selectors.gd")
const U_NavigationActions := preload("res://scripts/state/actions/u_navigation_actions.gd")

@onready var _dropdown: OptionButton = $HBoxContainer/OptionButton
@onready var _apply_button: Button = $HBoxContainer/ApplyButton

var _manager: Node = null

func _on_panel_ready() -> void:
	_manager = get_tree().get_first_node_in_group("input_profile_manager")
	if _manager == null:
		push_warning("InputProfileSelector: M_InputProfileManager not found")
		return
	_populate_profiles()
	if _apply_button != null and not _apply_button.pressed.is_connected(_on_apply_pressed):
		_apply_button.pressed.connect(_on_apply_pressed)

func _populate_profiles() -> void:
	_dropdown.clear()
	if _manager == null:
		return
	var ids: Array[String] = _manager.get_available_profile_ids()
	for i in range(ids.size()):
		_dropdown.add_item(ids[i])
	# Select currently active from settings if available
	var store := get_store()
	if store == null:
		return
	var state: Dictionary = store.get_state()
	var active_id := U_InputSelectors.get_active_profile_id(state)
	for idx in range(_dropdown.item_count):
		if _dropdown.get_item_text(idx) == active_id:
			_dropdown.select(idx)
			break

func _on_apply_pressed() -> void:
	if _manager == null:
		return
	var selected_text := _dropdown.get_item_text(_dropdown.get_selected())
	_manager.switch_profile(selected_text)
	_close_overlay()

func _close_overlay() -> void:
	var store := get_store()
	if store != null:
		store.dispatch(U_NavigationActions.close_top_overlay())

func _on_back_pressed() -> void:
	_close_overlay()
