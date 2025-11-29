extends RefCounted
class_name U_DebugSelectors

static func get_debug_settings(state: Dictionary) -> Dictionary:
	if state == null:
		return {}
	var debug_state: Variant = state.get("debug", {})
	if debug_state is Dictionary:
		return (debug_state as Dictionary).duplicate(true)
	return {}

static func is_touchscreen_disabled(state: Dictionary) -> bool:
	return bool(get_debug_settings(state).get("disable_touchscreen", false))
