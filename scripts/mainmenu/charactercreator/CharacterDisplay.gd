extends Node2D

@onready var character_renderer = $CharacterRenderer
# @onready var file_dialog = $FileDialog
# @onready var random_button = $CanvasLayer/UI/RandomButton
#@onready var save_button = $CanvasLayer/UI/SaveButton
# @onready var load_button = $CanvasLayer/UI/LoadButton

func _ready():
	# Connect UI buttons
#	random_button.pressed.connect(_on_random_button_pressed)
#	save_button.pressed.connect(_on_save_button_pressed)
#	load_button.pressed.connect(_on_load_button_pressed)
	
	# Create default character if none exists
	if GlobalState.current_character_path == "":
		GlobalState.current_character_path = "user://default_character.json"
		_create_default_character()
	
	# Load character
	character_renderer.load_character(GlobalState.current_character_path)

func _create_default_character():
	var default_character = {
		"appearance": {
			"head": {"type": 0, "scale": 1.0},
			"eyes": {"type": 0, "scale": 1.0},
			"ears": {"type": 0, "scale": 1.0},
			"nose": {"type": 0, "scale": 1.0},
			"mouth": {"type": 0, "scale": 1.0},
			"chin": {"type": 0, "scale": 1.0},
			"neck": {"type": 0, "scale": 1.0}
		}
	}
	
	var file = FileAccess.open(GlobalState.current_character_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(default_character)
		file.store_string(json_string)
	else:
		print("Could not create default character file")

func _on_random_button_pressed():
	var character_data = character_renderer.character_data
	
	# Randomize head-related body parts
	var head_parts = ["head", "eyes", "ears", "nose", "mouth", "chin", "neck"]
	
	for part in head_parts:
		var part_upper = part.capitalize()
		var types_count = character_renderer.part_types[part_upper].size()
		
		character_data["appearance"][part]["type"] = randi() % types_count
		character_data["appearance"][part]["scale"] = randf_range(0.8, 1.2)
	
	# Save and reload
	var file = FileAccess.open(GlobalState.current_character_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(character_data)
		file.store_string(json_string)
		character_renderer.character_data = character_data
		character_renderer.queue_redraw()
	else:
		print("Could not save random character")

func _on_save_button_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.filters = ["*.json"]
	file_dialog.current_path = "user://character.json"
	file_dialog.popup_centered(Vector2(800, 600))

func _on_load_button_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_USERDATA
	file_dialog.filters = ["*.json"]
	file_dialog.popup_centered(Vector2(800, 600))

func _on_file_dialog_file_selected(path):
	if file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
		# Save character
		var file = FileAccess.open(path, FileAccess.WRITE)
		if file:
			var json_string = JSON.stringify(character_renderer.character_data)
			file.store_string(json_string)
			GlobalState.current_character_path = path
		else:
			print("Could not save character")
	else:
		# Load character
		if character_renderer.load_character(path):
			GlobalState.current_character_path = path
		else:
			print("Could not load character")
