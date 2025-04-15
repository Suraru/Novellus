extends Control

@onready var character_list = $HBoxContainer/LeftPanel/CharacterList
@onready var edit_button = $ButtonPanel/EditButton
@onready var delete_button = $ButtonPanel/DeleteButton
@onready var portrait = $HBoxContainer/RightPanel/Portrait
@onready var front = $HBoxContainer/RightPanel/SpritePreview/Front
@onready var back = $HBoxContainer/RightPanel/SpritePreview/Back
@onready var left = $HBoxContainer/RightPanel/SpritePreview/Left
@onready var right = $HBoxContainer/RightPanel/SpritePreview/Right
@onready var start_button = $ButtonPanel/StartButton

var characters = []
var selected_file_path := ""

func _ready():
	character_list.item_selected.connect(_on_character_selected)
	edit_button.pressed.connect(_on_edit_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	$ButtonPanel/CreateButton.pressed.connect(_on_create_pressed)
	$ButtonPanel/BackButton.pressed.connect(_on_back_pressed)
	start_button.pressed.connect(_on_start_pressed)
	_load_characters()

func _load_characters():
	character_list.clear()
	characters.clear()
	selected_file_path = ""
	delete_button.disabled = true
	edit_button.disabled = true
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
						var label = "%s | Age: %s | Race: %s | Location: %s" % [
							json.get("fullname", "Unknown"),
							str(json.get("age", "??")),
							json.get("race", "Unknown"),
							json.get("location", "Unknown")
						]
						character_list.add_item(label)
			file_name = dir.get_next()
		dir.list_dir_end()

		if not found:
			character_list.add_item("You have no saved characters! Create one to begin.")
			character_list.select(0)
			character_list.set_item_disabled(0, true)

func _on_character_selected(index):
	if index < characters.size():
		selected_file_path = characters[index]["file"]
		edit_button.disabled = false
		delete_button.disabled = false
		start_button.disabled = false
		GlobalState.current_character_path = selected_file_path
	else:
		edit_button.disabled = true
		delete_button.disabled = true
		start_button.disabled = true
	# Load portrait/sprites here later

func _on_edit_pressed():
	if selected_file_path != "":
		GlobalState.current_character_path = selected_file_path
		GlobalState.is_editing_character = true
		get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/ChangeAppearance.tscn")

func _on_delete_pressed():
	if selected_file_path != "":
		var dir := DirAccess.open("res://characters")
		if dir and dir.file_exists(selected_file_path):
			dir.remove(selected_file_path)
			_load_characters()

func _on_create_pressed():
	var new_character = {
		"name": "New",
		"surname": "Character",
		"fullname": "New Character",
		"gender": "Male",
		"location":"The Void",
		"status":"Alive",
	}
	var filename = "res://characters/character_%d.json" % Time.get_unix_time_from_system()
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(JSON.stringify(new_character, "	"))
	GlobalState.current_character_path = filename
	file.close()
	_load_characters()
	GlobalState.is_editing_character = false
	get_tree().change_scene_to_file("res://scenes/mainmenu/charactercreator/RaceSelection.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")

func _on_start_pressed():
	if selected_file_path != "":
		print("Starting game with character: " + selected_file_path)
		get_tree().change_scene_to_file("res://scenes/SandboxWorld.tscn")
