extends Node

var current_character_path: String = ""
var is_editing_character: bool = false
var current_save_path: String = ""  # Add this line to store the current save file path

func _ready():
	# Initialize with default path if none exists
	if current_character_path == "":
		current_character_path = "user://default_character.json"
