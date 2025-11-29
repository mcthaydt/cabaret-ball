@icon("res://resources/editor_icons/utility.svg")
extends "res://scripts/ui/base/base_panel.gd"
class_name BaseMenuScreen

## Base class for full-screen UI scenes such as main menu, game over, and victory.
##
## Inherits the common store / focus / back handling from BasePanel and provides
## a dedicated hook for menu-specific setup.

func _ready() -> void:
	await super._ready()
