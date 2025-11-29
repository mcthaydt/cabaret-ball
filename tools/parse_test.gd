extends SceneTree

func _init():
	var script := preload("res://scripts/state/m_state_store.gd")
	var inst = script.new()
	print("Parsed and instantiated: ", inst)
	quit()

