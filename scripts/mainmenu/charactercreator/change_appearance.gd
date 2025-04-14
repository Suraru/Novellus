extends Control

var character_data = {}
var body_parts = ["Hair", "Head", "Eyes", "Ears", "Nose", "Mouth", "Chin", "Neck", "Torso", "Arms", "Hands", "Belly", "Back", "Tail", "Legs", "Feet"]
var body_part_descriptions = ["normal", "wide", "thin"]
@onready var back_button = $ButtonPanel/BackButton
@onready var start_button = $ButtonPanel/StartButton

func _ready():
	# Connect UI buttons
	start_button.pressed.connect(on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	if GlobalState.is_editing_character:
		back_button.disabled = true
	
	# Connect navigation buttons for each body part
	for part in body_parts:
		var part_lower = part.to_lower()
		# Connect back and forward buttons
		var back_button = get_node("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "BackButton")
		var forward_button = get_node("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "ForwardButton")
		var slider = get_node("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/MarginContainer/" + part + "HSlider")
		
		back_button.pressed.connect(_on_part_back_pressed.bind(part_lower))
		forward_button.pressed.connect(_on_part_forward_pressed.bind(part_lower))
		slider.value_changed.connect(_on_slider_value_changed.bind(part_lower))
	
	# Load character data
	load_character_data()
	update_ui()

func load_character_data():
	var character_file_path = GlobalState.current_character_path
	var file = FileAccess.open(character_file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		var json_result = JSON.parse_string(json_string)
		if json_result:
			character_data = json_result
			
			# Initialize missing body parts with default values
			for part in body_parts:
				if not character_data.has("appearance") or not character_data["appearance"].has(part.to_lower()):
					if not character_data.has("appearance"):
						character_data["appearance"] = {}
					character_data["appearance"][part.to_lower()] = 0
		else:
			print("Error parsing JSON file")
	else:
		print("Could not open character file")
		# Initialize with default values
		character_data = {"appearance": {}}
		for part in body_parts:
			character_data["appearance"][part.to_lower()] = 0

func save_character_data():
	var character_file_path = GlobalState.current_character_path
	var file = FileAccess.open(character_file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(character_data)
		file.store_string(json_string)
	else:
		print("Could not open character file for writing")

func update_ui():
	# Update all body part labels to show current values
	for part in body_parts:
		var part_lower = part.to_lower()
		var value = 0
		
		# Get current value from character data
		if character_data.has("appearance") and character_data["appearance"].has(part_lower):
			value = character_data["appearance"][part_lower]
		
		# Update the label text
		var description = "normal"
		if value >= 0 and value < body_part_descriptions.size():
			description = body_part_descriptions[value]
		
		var display_label = get_node("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/" + part + "ButtonsContainer/" + part + "Display")
		display_label.text = description
		
		# Update slider
		var slider = get_node("SelectionMargin/ScrollContainer/TabContainer/BodyPartContainer/" + part + "Container/MarginContainer/" + part + "HSlider")
		var slider_value = (value / float(body_part_descriptions.size() - 1)) * 100
		slider.value = slider_value

func _on_part_back_pressed(part_name):
	var current_value = character_data["appearance"][part_name]
	
	# Decrement value (with wrap-around)
	current_value = (current_value - 1) % body_part_descriptions.size()
	if current_value < 0:
		current_value = body_part_descriptions.size() - 1
	
	character_data["appearance"][part_name] = current_value
	update_ui()

func _on_part_forward_pressed(part_name):
	var current_value = character_data["appearance"][part_name]
	
	# Increment value (with wrap-around)
	current_value = (current_value + 1) % body_part_descriptions.size()
	
	character_data["appearance"][part_name] = current_value
	update_ui()

func _on_slider_value_changed(value, part_name):
	# Convert slider value (0-100) to index in descriptions array
	var index = int(round(value / 100.0 * (body_part_descriptions.size() - 1)))
	character_data["appearance"][part_name] = index
	update_ui()

func on_start_pressed():
	save_character_data()
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterBuild.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")
