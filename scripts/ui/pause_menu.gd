@icon("res://resources/editor_icons/utility.svg")
extends "res://scripts/ui/base/base_overlay.gd"

## Pause Menu - overlay wired into navigation actions
##
## Buttons dispatch navigation actions instead of calling Scene Manager directly.

const U_NavigationActions := preload("res://scripts/state/actions/u_navigation_actions.gd")

const OVERLAY_SETTINGS := StringName("settings_menu_overlay")
const OVERLAY_INPUT_PROFILE := StringName("input_profile_selector")
const OVERLAY_GAMEPAD_SETTINGS := StringName("gamepad_settings")
const OVERLAY_TOUCHSCREEN_SETTINGS := StringName("touchscreen_settings")
const OVERLAY_INPUT_REBINDING := StringName("input_rebinding")

@onready var _resume_button: Button = %ResumeButton
@onready var _settings_button: Button = %SettingsButton
@onready var _input_profiles_button: Button = %InputProfilesButton
@onready var _gamepad_settings_button: Button = %GamepadSettingsButton
@onready var _touchscreen_settings_button: Button = %TouchscreenSettingsButton
@onready var _rebind_controls_button: Button = %RebindControlsButton
@onready var _quit_button: Button = %QuitButton

func _on_panel_ready() -> void:
	print("[PauseMenu] _on_panel_ready called")
	print("[PauseMenu] Button references: resume=%s, settings=%s, gamepad=%s, touchscreen=%s, rebind=%s, quit=%s" % [
		_resume_button != null,
		_settings_button != null,
		_gamepad_settings_button != null,
		_touchscreen_settings_button != null,
		_rebind_controls_button != null,
		_quit_button != null
	])
	_connect_buttons()

	# DIAGNOSTIC: Add gui_input listeners to buttons
	if _resume_button != null:
		_resume_button.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch:
				print("[PauseMenu] Resume button received gui_input: ", event)
		)
	if _settings_button != null:
		_settings_button.gui_input.connect(func(event: InputEvent):
			if event is InputEventScreenTouch:
				print("[PauseMenu] Settings button received gui_input: ", event)
		)

func _connect_buttons() -> void:
	if _resume_button != null and not _resume_button.pressed.is_connected(_on_resume_pressed):
		_resume_button.pressed.connect(_on_resume_pressed)
	if _settings_button != null and not _settings_button.pressed.is_connected(_on_settings_pressed):
		_settings_button.pressed.connect(_on_settings_pressed)
	if _input_profiles_button != null and not _input_profiles_button.pressed.is_connected(_on_input_profiles_pressed):
		_input_profiles_button.pressed.connect(_on_input_profiles_pressed)
	if _gamepad_settings_button != null and not _gamepad_settings_button.pressed.is_connected(_on_gamepad_settings_pressed):
		_gamepad_settings_button.pressed.connect(_on_gamepad_settings_pressed)
	if _touchscreen_settings_button != null and not _touchscreen_settings_button.pressed.is_connected(_on_touchscreen_settings_pressed):
		_touchscreen_settings_button.pressed.connect(_on_touchscreen_settings_pressed)
	if _rebind_controls_button != null and not _rebind_controls_button.pressed.is_connected(_on_rebind_controls_pressed):
		_rebind_controls_button.pressed.connect(_on_rebind_controls_pressed)
	if _quit_button != null and not _quit_button.pressed.is_connected(_on_quit_pressed):
		_quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed() -> void:
	print("[PauseMenu] Resume button pressed")
	_dispatch_navigation(U_NavigationActions.close_pause())

func _on_settings_pressed() -> void:
	print("[PauseMenu] Settings button pressed")
	_dispatch_navigation(U_NavigationActions.open_overlay(OVERLAY_SETTINGS))

func _on_input_profiles_pressed() -> void:
	print("[PauseMenu] Input Profiles button pressed")
	_dispatch_navigation(U_NavigationActions.open_overlay(OVERLAY_INPUT_PROFILE))

func _on_gamepad_settings_pressed() -> void:
	print("[PauseMenu] Gamepad Settings button pressed")
	_dispatch_navigation(U_NavigationActions.open_overlay(OVERLAY_GAMEPAD_SETTINGS))

func _on_touchscreen_settings_pressed() -> void:
	print("[PauseMenu] Touchscreen Settings button pressed")
	_dispatch_navigation(U_NavigationActions.open_overlay(OVERLAY_TOUCHSCREEN_SETTINGS))

func _on_rebind_controls_pressed() -> void:
	print("[PauseMenu] Rebind Controls button pressed")
	_dispatch_navigation(U_NavigationActions.open_overlay(OVERLAY_INPUT_REBINDING))

func _on_quit_pressed() -> void:
	print("[PauseMenu] Quit button pressed")
	_dispatch_navigation(U_NavigationActions.return_to_main_menu())

func _on_back_pressed() -> void:
	_on_resume_pressed()

func _dispatch_navigation(action: Dictionary) -> void:
	if action.is_empty():
		return
	var store := get_store()
	if store == null:
		return
	store.dispatch(action)
