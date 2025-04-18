extends Control

# Scene paths
const RACE_SELECTION_SCENE = "res://scenes/mainmenu/charactercreator/RaceSelection.tscn"
const CHARACTER_BUILD_SCENE = "res://scenes/mainmenu/charactercreator/CharacterBuild.tscn"

# Node references
@onready var back_button = $ButtonPanel/BackButton
@onready var start_button = $ButtonPanel/StartButton

func _ready():
	# Connect button signals
	back_button.pressed.connect(_on_back_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

# Button handlers
func _on_back_button_pressed():
	# Go back to race selection
	get_tree().change_scene_to_file(RACE_SELECTION_SCENE)

func _on_start_button_pressed():
	# Go to character build
	get_tree().change_scene_to_file(CHARACTER_BUILD_SCENE)
