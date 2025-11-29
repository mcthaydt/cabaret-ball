extends GutTest

const U_ButtonPromptRegistry := preload("res://scripts/ui/u_button_prompt_registry.gd")
const M_InputDeviceManager := preload("res://scripts/managers/m_input_device_manager.gd")

const DEVICE_TYPE := M_InputDeviceManager.DeviceType

func before_each() -> void:
	_reset_registry()

func after_each() -> void:
	_reset_registry()

func test_register_prompt_provides_binding_label() -> void:
	var action := StringName("test_prompt_action")
	var texture_path := "res://resources/button_prompts/keyboard/key_e.png"
	U_ButtonPromptRegistry.register_prompt(action, DEVICE_TYPE.KEYBOARD_MOUSE, texture_path, "E")

	var label := U_ButtonPromptRegistry.get_binding_label(action, DEVICE_TYPE.KEYBOARD_MOUSE)
	assert_eq(label, "E", "Registry should return explicit binding label for registered prompts")

func test_get_prompt_returns_null_when_unused() -> void:
	var texture := U_ButtonPromptRegistry.get_prompt(StringName("interact"), DEVICE_TYPE.KEYBOARD_MOUSE)
	assert_null(texture, "Prompt registry should not supply textures when dynamic icons are used")

func test_get_prompt_text_uses_keyboard_binding_label() -> void:
	var text := U_ButtonPromptRegistry.get_prompt_text(StringName("jump"), DEVICE_TYPE.KEYBOARD_MOUSE)
	assert_eq(text, "Press [Space]", "Keyboard fallback text should reflect primary key binding")

func test_get_prompt_text_returns_gamepad_label_from_registry_metadata() -> void:
	var action := StringName("test_gamepad_action")
	var texture_path := "res://resources/button_prompts/gamepad/button_west.png"
	U_ButtonPromptRegistry.register_prompt(action, DEVICE_TYPE.GAMEPAD, texture_path, "West")
	var text := U_ButtonPromptRegistry.get_prompt_text(action, DEVICE_TYPE.GAMEPAD)
	assert_eq(text, "Press [West]", "Gamepad fallback should derive label from registered prompt metadata")

func test_get_prompt_text_uses_touchscreen_template() -> void:
	var text := U_ButtonPromptRegistry.get_prompt_text(StringName("jump"), DEVICE_TYPE.TOUCHSCREEN)
	assert_eq(text, "Tap Jump", "Touchscreen fallback should use tap template with capitalized action name")

func test_ui_accept_uses_keyboard_and_gamepad_labels() -> void:
	var keyboard_text := U_ButtonPromptRegistry.get_prompt_text(StringName("ui_accept"), DEVICE_TYPE.KEYBOARD_MOUSE)
	assert_eq(keyboard_text, "Press [Enter]", "ui_accept should display Enter for keyboard prompts")
	var gamepad_text := U_ButtonPromptRegistry.get_prompt_text(StringName("ui_accept"), DEVICE_TYPE.GAMEPAD)
	assert_eq(gamepad_text, "Press [A]", "ui_accept should display A for gamepad prompts")

func test_ui_cancel_and_pause_use_expected_touch_and_gamepad_labels() -> void:
	var cancel_text := U_ButtonPromptRegistry.get_prompt_text(StringName("ui_cancel"), DEVICE_TYPE.GAMEPAD)
	assert_eq(cancel_text, "Press [B]", "ui_cancel should map to B for gamepad prompts")
	var pause_touch_text := U_ButtonPromptRegistry.get_prompt_text(StringName("ui_pause"), DEVICE_TYPE.TOUCHSCREEN)
	assert_eq(pause_touch_text, "Tap Pause", "ui_pause should present pause label for touchscreen")

static func _reset_registry() -> void:
	U_ButtonPromptRegistry._clear_for_tests()
