extends GutTest

const ButtonPromptScene := preload("res://scenes/ui/button_prompt.tscn")
const M_StateStore := preload("res://scripts/state/m_state_store.gd")
const M_InputDeviceManager := preload("res://scripts/managers/m_input_device_manager.gd")
const RS_StateStoreSettings := preload("res://scripts/state/resources/rs_state_store_settings.gd")
const RS_BootInitialState := preload("res://scripts/state/resources/rs_boot_initial_state.gd")
const RS_MenuInitialState := preload("res://scripts/state/resources/rs_menu_initial_state.gd")
const RS_GameplayInitialState := preload("res://scripts/state/resources/rs_gameplay_initial_state.gd")
const RS_SceneInitialState := preload("res://scripts/state/resources/rs_scene_initial_state.gd")
const U_StateHandoff := preload("res://scripts/state/utils/u_state_handoff.gd")
const U_ButtonPromptRegistry := preload("res://scripts/ui/u_button_prompt_registry.gd")
const DeviceType := M_InputDeviceManager.DeviceType

var _store: M_StateStore
var _device_manager: M_InputDeviceManager
var _button_prompt: Control

func before_each() -> void:
	U_StateHandoff.clear_all()
	_store = M_StateStore.new()
	_store.settings = RS_StateStoreSettings.new()
	_store.boot_initial_state = RS_BootInitialState.new()
	_store.menu_initial_state = RS_MenuInitialState.new()
	_store.gameplay_initial_state = RS_GameplayInitialState.new()
	_store.scene_initial_state = RS_SceneInitialState.new()
	add_child_autofree(_store)

	_device_manager = M_InputDeviceManager.new()
	add_child_autofree(_device_manager)

	_button_prompt = ButtonPromptScene.instantiate()
	add_child_autofree(_button_prompt)

	_register_default_prompts()

	await _await_frames(2)
	var keyboard_event := InputEventKey.new()
	keyboard_event.pressed = true
	keyboard_event.physical_keycode = KEY_E
	_device_manager._input(keyboard_event)
	await _await_frames(1)

func after_each() -> void:
	U_StateHandoff.clear_all()
	_store = null
	_device_manager = null
	_button_prompt = null
	U_ButtonPromptRegistry._clear_for_tests()

func _register_default_prompts() -> void:
	U_ButtonPromptRegistry._clear_for_tests()
	U_ButtonPromptRegistry.register_prompt(
		StringName("interact"),
		DeviceType.KEYBOARD_MOUSE,
		"res://resources/button_prompts/keyboard/key_e.png",
		"E"
	)
	U_ButtonPromptRegistry.register_prompt(
		StringName("interact"),
		DeviceType.GAMEPAD,
		"res://resources/button_prompts/gamepad/button_west.png",
		"West"
	)
	U_ButtonPromptRegistry.register_prompt(
		StringName("jump"),
		DeviceType.KEYBOARD_MOUSE,
		"res://resources/button_prompts/keyboard/key_space.png",
		"Space"
	)
	U_ButtonPromptRegistry.register_prompt(
		StringName("jump"),
		DeviceType.GAMEPAD,
		"res://resources/button_prompts/gamepad/button_south.png",
		"South"
	)

func _await_frames(count: int) -> void:
	for _i in count:
		await get_tree().process_frame

func test_show_prompt_updates_icon_and_text() -> void:
	var button_prompt := _button_prompt
	assert_not_null(button_prompt, "Button prompt scene should instantiate")

	button_prompt.call("show_prompt", StringName("interact"), "Read")
	await _await_frames(1)

	var text_icon: Control = button_prompt.get_node("TextIcon")
	var text_icon_label: Label = text_icon.get_node("Label")
	var label: Label = button_prompt.get_node("Text")

	assert_true(button_prompt.visible, "Prompt container should be visible after show")
	assert_true(text_icon.visible, "Text icon should be visible when prompt shown")
	assert_eq(text_icon_label.text, "E", "Text icon should reflect keyboard binding")
	assert_eq(label.text, "Read", "Prompt text should match provided value")

	_device_manager._on_joy_connection_changed(1, true)
	await _await_frames(1)
	var motion := InputEventJoypadMotion.new()
	motion.device = 1
	motion.axis = JOY_AXIS_LEFT_X
	motion.axis_value = 0.5
	_device_manager._input(motion)
	await _await_frames(1)

	assert_true(text_icon.visible, "Text icon should remain visible after device change")
	assert_eq(text_icon_label.text, "West", "Text icon should update to current device binding")
	assert_eq(label.text, "Read", "Prompt text should remain unchanged when device switches")

func test_missing_icon_falls_back_to_text_label() -> void:
	var action := StringName("custom_action")
	U_ButtonPromptRegistry.register_prompt(action, DeviceType.GAMEPAD, "res://resources/button_prompts/gamepad/missing_button.png")

	_device_manager._on_joy_connection_changed(0, true)
	await _await_frames(1)
	var motion := InputEventJoypadMotion.new()
	motion.device = 0
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 0.4
	_device_manager._input(motion)
	await _await_frames(1)

	_button_prompt.call("show_prompt", action, "Activate")
	await _await_frames(1)

	var label: Label = _button_prompt.get_node("Text")
	var text_icon: Control = _button_prompt.get_node("TextIcon")
	var text_icon_label: Label = text_icon.get_node("Label")

	assert_true(text_icon.visible, "Text icon should show when representing binding")
	assert_eq(text_icon_label.text, "Missing Button",
		"Text icon should show derived label when no binding available")
	assert_eq(label.text, "Activate", "Prompt text should remain provided label")

func test_hide_prompt_clears_state() -> void:
	_button_prompt.call("show_prompt", StringName("interact"), "Read")
	await _await_frames(1)

	_button_prompt.call("hide_prompt")
	await _await_frames(1)

	var label: Label = _button_prompt.get_node("Text")
	var text_icon: Control = _button_prompt.get_node("TextIcon")
	var text_icon_label: Label = text_icon.get_node("Label")

	assert_false(_button_prompt.visible, "Prompt should hide after hide_prompt call")
	assert_false(text_icon.visible, "Text icon should hide after hide_prompt")
	assert_eq(text_icon_label.text, "", "Text icon label should clear after hide_prompt")
	assert_eq(label.text, "", "Label text should clear after hide_prompt")

func test_interact_prompt_reflects_custom_binding() -> void:
	await _assert_prompt_updates_binding_label(StringName("interact"), "Read", Key.KEY_F)

func test_jump_prompt_reflects_custom_binding() -> void:
	await _assert_prompt_updates_binding_label(StringName("jump"), "Jump", Key.KEY_Q)

func _capture_action_events(action: StringName) -> Array[InputEvent]:
	var results: Array[InputEvent] = []
	if not InputMap.has_action(action):
		return results
	for event in InputMap.action_get_events(action):
		if event is InputEvent:
			var copy := (event as InputEvent).duplicate()
			if copy is InputEvent:
				results.append(copy)
	return results

func _restore_action_events(action: StringName, events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action).duplicate():
		InputMap.action_erase_event(action, event)
	for event in events:
		InputMap.action_add_event(action, event)

func _assert_prompt_updates_binding_label(action: StringName, prompt: String, keycode: int) -> void:
	_button_prompt.call("show_prompt", action, prompt)
	await _await_frames(1)
	var text_icon: Control = _button_prompt.get_node("TextIcon")
	var text_icon_label: Label = text_icon.get_node("Label")
	var label: Label = _button_prompt.get_node("Text")
	assert_true(is_instance_valid(text_icon), "Text icon should remain valid while prompt active")
	assert_true(is_instance_valid(label), "Label should remain valid while prompt active")
	assert_true(text_icon.visible, "Text icon should be visible for default binding")
	assert_eq(text_icon_label.text, U_ButtonPromptRegistry.get_binding_label(action, DeviceType.KEYBOARD_MOUSE),
		"Text icon should reflect current binding label")
	assert_eq(label.text, prompt, "Default prompt keeps provided label when icon available")

	var original_events := _capture_action_events(action)
	_set_action_binding_to_key(action, keycode)
	_button_prompt.call("show_prompt", action, prompt)
	await _await_frames(1)
	text_icon = _button_prompt.get_node("TextIcon")
	text_icon_label = text_icon.get_node("Label")
	label = _button_prompt.get_node("Text")

	assert_true(text_icon.visible, "Text icon should remain visible after rebinding")
	assert_eq(text_icon_label.text, OS.get_keycode_string(keycode),
		"Text icon should display rebound key label")
	assert_eq(label.text, prompt, "Prompt text should remain provided label when fallback icon used")

	_restore_action_events(action, original_events)

func _set_action_binding_to_key(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action).duplicate():
		InputMap.action_erase_event(action, event)
	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action, key_event)
