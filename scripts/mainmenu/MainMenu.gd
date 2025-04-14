extends Control

@onready var start_button = $VBoxContainer/StartButton
@onready var history_button = $VBoxContainer/HistoryButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var exit_button = $VBoxContainer/ExitButton

func _ready():
	start_button.pressed.connect(on_start_pressed)
	history_button.pressed.connect(on_history_pressed)
	settings_button.pressed.connect(on_settings_pressed)
	exit_button.pressed.connect(on_exit_pressed)

func on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu/CharacterCreator.tscn")

func on_history_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu/History.tscn")

func on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/MainMenu/Settings.tscn")

func on_exit_pressed():
	get_tree().quit()
