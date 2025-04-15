extends Control

@onready var background = $Characterbg
@onready var start_button = $VBoxContainer/StartButton
@onready var history_button = $VBoxContainer/HistoryButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var exit_button = $VBoxContainer/ExitButton

func _ready():
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	_on_viewport_size_changed()
	start_button.pressed.connect(on_start_pressed)
	history_button.pressed.connect(on_history_pressed)
	settings_button.pressed.connect(on_settings_pressed)
	exit_button.pressed.connect(on_exit_pressed)

func _on_viewport_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	var texture_size = background.texture.get_size()
	
	# Calculate scale to cover the entire viewport
	var scale_x = viewport_size.x / texture_size.x
	var scale_y = viewport_size.y / texture_size.y
	var scale = max(scale_x, scale_y)
	
	background.scale = Vector2(scale, scale)
	
	# Center the background
	background.position = viewport_size / 2
	background.centered = true

func on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")

func on_history_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/History.tscn")

func on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/Settings.tscn")

func on_exit_pressed():
	get_tree().quit()
