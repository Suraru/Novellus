extends Control

@onready var background = $Characterbg

@onready var save_file_list = $MainContainer/SaveFilesPanel/SaveFileList
@onready var new_character_button = $MainContainer/SaveFilesPanel/NewCharacterButton
@onready var no_character_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/NoCharacterLabel
@onready var character_portrait = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterPortrait
@onready var character_details = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails
@onready var name_label = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/NameLabel
@onready var age_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/AgeValue
@onready var race_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/RaceValue
@onready var gender_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/GenderValue
@onready var lifestage_value = $MainContainer/CharacterPreviewPanel/CharacterInfoPanel/VBoxContainer/CharacterDetails/DetailGrid/LifestageValue
@onready var start_button = $MainContainer/CharacterPreviewPanel/StartButton
@onready var back_button = $ButtonPanel/BackButton

var characters = []
var selected_file_path := ""

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	# Connect signals
	save_file_list.item_selected.connect(_on_character_selected)
	new_character_button.pressed.connect(_on_new_character_pressed)
	start_button.pressed.connect(_on_start_pressed)
	back_button.pressed.connect(_on_back_pressed)
	
	# Load character save files
	_load_saved_characters()

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.centered = false

func _load_saved_characters():
	save_file_list.clear()
	characters.clear()
	selected_file_path = ""
	start_button.disabled = true
	
	var dir = DirAccess.open("res://characters")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var found = false
		while file_name != "":
			if file_name.ends_with(".json"):
				var file = FileAccess.open("res://characters/" + file_name, FileAccess.READ)
				if file:
					var json_text = file.get_as_text()
					var json = JSON.parse_string(json_text)
					if typeof(json) == TYPE_DICTIONARY:
						found = true
						characters.append({
							"data": json,
							"file": "res://characters/" + file_name
						})
						var label = "%s | Age: %s | Race: %s" % [
							json.get("fullname", "Unknown"),
							str(json.get("age", "??")),
							json.get("race", "Unknown")
						]
						save_file_list.add_item(label)
			file_name = dir.get_next()
		dir.list_dir_end()

		if not found:
			save_file_list.add_item("No saved characters found.")
			save_file_list.select(0)
			save_file_list.set_item_disabled(0, true)

func _on_character_selected(index):
	if index < 0 or index >= characters.size():
		no_character_label.visible = true
		character_portrait.visible = false
		character_details.visible = false
		start_button.disabled = true
		selected_file_path = ""
		return
		
	selected_file_path = characters[index]["file"]
	var character_data = characters[index]["data"]
	
	# Update character preview
	no_character_label.visible = false
	character_details.visible = true
	
	# Show portrait if available
	if character_data.has("portrait_path") and FileAccess.file_exists(character_data["portrait_path"]):
		character_portrait.texture = load(character_data["portrait_path"])
		character_portrait.visible = true
	else:
		character_portrait.visible = false
	
	# Update character details
	name_label.text = character_data.get("fullname", "Unknown")
	age_value.text = str(character_data.get("age", "??"))
	race_value.text = character_data.get("race", "Unknown")
	gender_value.text = character_data.get("gender", "Unknown")
	
	# Calculate lifestage
	var race = character_data.get("race", "Human")
	var age = int(character_data.get("age", 25))
	var lifestage = GlobalFormulas.get_lifestage(race, age)
	lifestage_value.text = lifestage
	
	# Enable start button
	start_button.disabled = false
	GlobalState.current_character_path = selected_file_path

func _on_new_character_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/CharacterSelection.tscn")

func _on_start_pressed():
	if selected_file_path != "":
		# Load the sandbox world or game scene here
		# For now, just print a message
		print("Starting game with character: " + selected_file_path)
		get_tree().change_scene_to_file("res://scenes/SandboxWorld.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/MainMenu.tscn")
