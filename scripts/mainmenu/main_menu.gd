extends Control

@onready var background = $Characterbg
@onready var title = $Title
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
	
	# Handle background scaling
	var bg_texture_size = background.texture.get_size()
	var bg_scale_x = viewport_size.x / bg_texture_size.x
	var bg_scale_y = viewport_size.y / bg_texture_size.y
	var scaling_factor = max(bg_scale_x, bg_scale_y)
	
	background.scale = Vector2(scaling_factor, scaling_factor)
	background.centered = false
	
	# Adjust title position
	title.position = Vector2(viewport_size.x * 0.4, viewport_size.y * 0.25)
	
	# Scale title based on screen width
	var scale_factor = viewport_size.x / 1920.0
	title.scale = Vector2(scale_factor, scale_factor)

func on_start_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/GameStart.tscn")

func on_history_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/History.tscn")

func on_settings_pressed():
	get_tree().change_scene_to_file("res://scenes/mainmenu/Settings.tscn")

func on_exit_pressed():
	get_tree().quit()
