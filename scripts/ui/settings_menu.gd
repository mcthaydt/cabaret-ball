@icon("res://resources/editor_icons/utility.svg")
extends "res://scripts/ui/base/base_overlay.gd"

## Settings Menu UI Controller
##
## Runs as either an overlay (pause → settings) or a standalone scene (legacy flows).
## Uses navigation actions for all back/close behavior.

const U_NavigationSelectors := preload("res://scripts/state/selectors/u_navigation_selectors.gd")
const U_NavigationActions := preload("res://scripts/state/actions/u_navigation_actions.gd")

@onready var _back_button: Button = $VBoxContainer/BackButton

const SETTINGS_OVERLAY_ID := StringName("settings_menu_overlay")

func _on_panel_ready() -> void:
	if _back_button != null and not _back_button.pressed.is_connected(_on_back_pressed):
		_back_button.pressed.connect(_on_back_pressed)
	_update_back_button_label()

func _on_back_pressed() -> void:
	var store := get_store()
	if store == null:
		return

	var nav_slice: Dictionary = store.get_state().get("navigation", {})
	var top_overlay: StringName = U_NavigationSelectors.get_top_overlay_id(nav_slice)
	if top_overlay == SETTINGS_OVERLAY_ID:
		store.dispatch(U_NavigationActions.close_top_overlay())
	else:
		store.dispatch(U_NavigationActions.return_to_main_menu())

func _update_back_button_label() -> void:
	if _back_button == null:
		return

	var store := get_store()
	if store == null:
		return

	var nav_slice: Dictionary = store.get_state().get("navigation", {})
	var top_overlay: StringName = U_NavigationSelectors.get_top_overlay_id(nav_slice)
	var is_overlay: bool = top_overlay == SETTINGS_OVERLAY_ID
	_back_button.text = "Back" if is_overlay else "Back to Main Menu"
